using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEngine.Networking;

namespace DragonReborn
{
	internal class AssetHttpApi : IHttpApi
    {
        private const string PathFormat = "{0}.download{1}";

        private struct Response
        {
            public string SavePath;
            public string DownloadPath;
            public uint CrcCheckValue;
            public Action<HttpResponseData> Callback;
			public Action<ulong, ulong> OnProgress;
            public bool IsRetry;
        }

        private readonly Dictionary<AssetHttpOperation, Response> _operations =
            new Dictionary<AssetHttpOperation, Response>();

        private readonly List<AssetHttpOperation> _removals = new List<AssetHttpOperation>();

        private readonly Crc32Algorithm _crcChecker = new Crc32Algorithm();

        public IHttpAsyncOperation Send(HttpRequestData requestData, Action<HttpResponseData> callback, Action<ulong, ulong> onProgress)
        {
            var downloader =
                MakeUniqueDownloadPath(requestData.SavePath, 20, requestData.IsRetry, out var downloadPath);
            
            if (downloader == null) // 创建文件失败
            {
                var responseData = new HttpResponseData
                {
                    ResponseCode = HttpResponseCode.CREATE_FILE_ERROR,
                    Url = requestData.Url,
                    SavePath = requestData.SavePath,
                };

                callback?.Invoke(responseData);

                return null;
            }

            var request = new UnityWebRequest {url = requestData.Url};

            switch (requestData.Method)
            {
                case HttpMethod.Get:
                    request.method = UnityWebRequest.kHttpVerbGET;
                    break;

                case HttpMethod.Post:
                    request.method = UnityWebRequest.kHttpVerbPOST;
                    break;
            }

            request.uploadHandler = new UploadHandlerRaw(requestData.RequestContent);
            request.disposeUploadHandlerOnDispose = true;

            request.downloadHandler = downloader;
            request.disposeDownloadHandlerOnDispose = true;

            foreach (var header in requestData.HeadersDict)
            {
                request.SetRequestHeader(header.Key, header.Value);
            }

            var operation = new AssetHttpOperation(request.SendWebRequest());
            _operations.Add(operation, new Response
            {
                SavePath = requestData.SavePath,
                DownloadPath = downloadPath,
                CrcCheckValue = requestData.CrcCheckValue,
                Callback = callback,
				OnProgress = onProgress,
                IsRetry = requestData.IsRetry
            });

            if (requestData.IsRetry)
            {
                NLogger.Error("[AssetHttpApi]Send Retry: URL = {0}, DownloadPath = {1}, SavePath = {2}",
                    requestData.Url, downloadPath, requestData.SavePath);
            }

            return operation;
        }

        private static DownloadHandlerFile MakeUniqueDownloadPath(string savePath, int maxRetry, bool isRetry,
            out string downloadPath)
        {
            var index = 0;

            do
            {
                downloadPath = string.Format(PathFormat, savePath, index++);
                try
                {
                    if (isRetry && File.Exists(downloadPath))
                    {
                        continue;
                    }

                    var downloader = new DownloadHandlerFile(downloadPath) {removeFileOnAbort = true};
                    return downloader;
                }
                catch
                {
                    // 创建文件失败
                }
            } while (index < maxRetry);

            return null;
        }

        public void Reset()
        {
            NLogger.TraceChannel("AssetHttpApi", "[AssetHttpApi]Reset");

            foreach (var pair in _operations)
            {
                var operation = pair.Key;
                if (!operation.IsDone)
                {
                    operation.Abort();
                }

                operation.Request.Dispose();
            }

            _operations.Clear();
            _removals.Clear();
        }

        public void Tick(float dt)
        {
            _removals.Clear();

            foreach (var pair in _operations)
            {
                var operation = pair.Key;
                var response = pair.Value;

                var error = operation.Request.error;
				if (!string.IsNullOrEmpty(error))
				{
					var responseData = new HttpResponseData
					{
						ResponseCode = HttpResponseCode.DOWNLOAD_ERROR,
						ResponseContent = Encoding.ASCII.GetBytes(operation.Request.error),
						Url = operation.Request.url,
						SavePath = response.SavePath,
						DownloadedBytes = operation.Request.downloadedBytes
					};

					if (response.IsRetry)
					{
						NLogger.Error(
							"[AssetHttpApi]Update operation Request error: URL = {0}, DownloadPath = {1}, SavePath = {2}, responseCode={3}, error ={4}",
							responseData.Url, response.DownloadPath, response.SavePath, responseData.ResponseCode, error);
					}

					// 如果下载失败，文件不会被自动删除，这里需要手动删除
					if (File.Exists(response.DownloadPath))
					{
						File.Delete(response.DownloadPath);
					}

					response.Callback?.Invoke(responseData);

					operation.Request.Dispose();
					_removals.Add(operation);
				}
				else if (operation.IsDone)
				{
					var responseData = new HttpResponseData
					{
						ResponseCode = operation.Request.responseCode,
						ResponseContent = null, // 内容已经写入硬盘
						Url = operation.Request.url,
						SavePath = response.SavePath,
						DownloadedBytes = operation.DownloadedBytes
					};

					if (File.Exists(response.SavePath))
					{
						File.Delete(response.SavePath);
					}

					if (response.IsRetry)
					{
						NLogger.Error(
							"[AssetHttpApi]Update operation IsDone: URL = {0}, DownloadPath = {1}, SavePath = {2}, responseCode={3}",
							responseData.Url, response.DownloadPath, response.SavePath, responseData.ResponseCode);
					}

					if (response.CrcCheckValue > 0)
					{
						TaskManager.Instance.RunAsync(() =>
						{
							uint downloadCrcValue = 0;
							lock (_crcChecker)
							{
								_crcChecker.Initialize();
								downloadCrcValue = _crcChecker.ComputeCrcValue(response.DownloadPath);
							}

							// do in main queue
							TaskManager.Instance.QueueOnMainThread(() =>
							{
								if (operation.IsAborted)
								{
									NLogger.Error(
										"[AssetHttpApi]Update operation IsAborted: URL = {0}, DownloadPath = {1}, SavePath = {2}",
										responseData.Url, response.DownloadPath, response.SavePath);
								}
								else
								{
									if (downloadCrcValue == response.CrcCheckValue)
									{
										ProcessOnOperationDone(response, responseData);
									}
									else
									{
										try
										{
											if (File.Exists(response.DownloadPath))
											{
												File.Delete(response.DownloadPath);
											}
										}
										catch (Exception e)
										{
											NLogger.Error(
												"[AssetHttpApi]Update: URL = {0}, DownloadPath = {1}, SavePath = {2}, Exception = {3}",
												responseData.Url, response.DownloadPath, response.SavePath,
												e.ToString());
										}

										responseData.ResponseCode = HttpResponseCode.CRC_CHECK_ERORR;

										NLogger.Error(
											"[AssetHttpApi]Update: URL = {0}, DownloadPath = {1}, SavePath = {2}, DownloadCrc = {3}, CrcCheck = {4}",
											responseData.Url, response.DownloadPath, response.SavePath,
											downloadCrcValue, response.CrcCheckValue);

										response.Callback?.Invoke(responseData);
									}
								}
							});
						});
					}
					else
					{
						ProcessOnOperationDone(response, responseData);
					}

					operation.Request.Dispose();
					_removals.Add(operation);
				}
				else if (operation.IsAborted)
				{
					_removals.Add(operation);
				}
				else
				{
					response.OnProgress?.Invoke(operation.DownloadedBytes, operation.ContentLength);
				}
            }

            foreach (var operation in _removals)
            {
                _operations.Remove(operation);
            }
        }

        private static void ProcessOnOperationDone(Response response, HttpResponseData responseData)
        {
            try
            {
                File.Move(response.DownloadPath, response.SavePath);
            }
            catch (Exception e)
            {
                responseData.ResponseCode = HttpResponseCode.MOVE_FILE_ERROR;

                var downloadExist = File.Exists(response.DownloadPath);
                var saveExist = File.Exists(response.SavePath);

                NLogger.Error(
                    "[AssetHttpApi]Update: URL = {0}, DownloadPath = {1}, SavePath = {2}, Exception = {3}, downloadExist = {4}, saveExist = {5}",
                    responseData.Url, response.DownloadPath,
                    response.SavePath, e.ToString(), downloadExist, saveExist);
            }

            if (response.IsRetry)
            {
                var downloadExist = File.Exists(response.DownloadPath);
                var saveExist = File.Exists(response.SavePath);

                NLogger.Error(
                    "[AssetHttpApi]ProcessOnOperationDone Retry: URL = {0}, DownloadPath = {1}, SavePath = {2}, responseCode={3}, downloadExist = {4}, saveExist = {5}",
                    responseData.Url,
                    response.DownloadPath,
                    response.SavePath, responseData.ResponseCode, downloadExist, saveExist);
            }

            response.Callback?.Invoke(responseData);
        }
    }
}
