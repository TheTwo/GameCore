using DragonReborn;

public class BaseRequestStrategy : HttpRequester.IRequestStrategy
{
	public static bool InLoading = false;
	public static bool IsNeedCrcCheck = true;

    protected virtual float MaxTimeOut => 10.0f;

    protected virtual int MaxRetryTimes => 10;

    public void GetRequestTimeOut (HttpRequester requester, out bool needRetry, out float timeOut, out bool reusePrevious)
	{
		if(requester.AlreadyTryTimes < MaxRetryTimes)
		{
			needRetry = true;
			reusePrevious = true;
			timeOut = MaxTimeOut;
		}
		else
		{
			needRetry = false;
			reusePrevious = true;
			timeOut = MaxTimeOut;
		}
	}

    public bool NeedRetryOnServerError()
    {
        return true;
    }

    public bool NeedCrcCheck()
    {
	    return IsNeedCrcCheck;
    }

    public bool IsConnected => true;

    public bool IsRetryImmediately(HttpResponseData responseData, out float timeout)
    {
	    if (responseData != null && responseData.ResponseCode == HttpResponseCode.CRC_CHECK_ERORR)//crc check error
	    {
		    timeout = 1;
	    }
	    else
	    {
		    timeout = 3;
	    }
	    return true;
    }
}

