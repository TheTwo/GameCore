import os
import tempfile
from PyPDF2 import PdfReader, PdfWriter
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter, A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from datetime import datetime

def get_system_font():
    """
    获取系统中文字体路径
    
    Returns:
        tuple: (是否成功注册字体, 字体名称)
    """
    font_paths = [
        '/System/Library/Fonts/STHeiti Light.ttc',  # macOS
        'C:/Windows/Fonts/simsun.ttc',  # Windows
        '/usr/share/fonts/truetype/arphic/uming.ttc',  # Linux
        '/usr/share/fonts/chinese/SimSun.ttf'  # 其他Linux路径
    ]
    
    for font_path in font_paths:
        try:
            pdfmetrics.registerFont(TTFont('SimSun', font_path))
            return True, 'SimSun'
        except:
            continue
    
    return False, 'Helvetica'

def add_header_to_pdf(input_path, output_path, header_text="彩色尾巴游戏APP"):
    """
    为PDF文件添加页眉
    
    Args:
        input_path (str): 输入PDF文件路径
        output_path (str): 输出PDF文件路径
        header_text (str): 页眉文字内容，默认为"彩色尾巴游戏APP"
        
    Raises:
        FileNotFoundError: 当输入文件不存在时
        PermissionError: 当没有写入权限时
        Exception: 其他处理过程中的错误
    """
    if not os.path.exists(input_path):
        raise FileNotFoundError(f"输入文件不存在: {input_path}")
    
    # 注册字体
    font_registered, font_name = get_system_font()
    if not font_registered:
        print("警告：无法找到系统中文字体，将使用默认字体")
    
    # 读取原始PDF
    try:
        pdf_reader = PdfReader(input_path)
        pdf_writer = PdfWriter()
    except Exception as e:
        raise Exception(f"无法打开PDF文件: {str(e)}")
    
    # 创建临时目录
    temp_dir = tempfile.mkdtemp()
    
    try:
        # 处理每一页
        for page_num in range(len(pdf_reader.pages)):
            temp_file = os.path.join(temp_dir, f'temp_header_{page_num}.pdf')
            
            # 获取原始页面尺寸
            page = pdf_reader.pages[page_num]
            page_width = float(page.mediabox.width)
            page_height = float(page.mediabox.height)
            
            # 创建临时页面添加页眉
            c = canvas.Canvas(temp_file, pagesize=(page_width, page_height))
            
            # 设置字体和字号
            font_size = 12  # 增大字号使页眉更明显
            c.setFont(font_name, font_size)
            
            # 计算文本宽度并居中显示
            text_width = c.stringWidth(header_text, font_name, font_size)
            x_position = (page_width - text_width) / 2
            
            # 绘制页眉（调整位置，距顶部更近）
            c.drawString(x_position, page_height - 20, header_text)
            
            # 添加一条横线
            c.line(50, page_height - 25, page_width - 50, page_height - 25)
            
            c.save()
            
            # 合并原页面和页眉
            with open(temp_file, 'rb') as temp_pdf:
                watermark = PdfReader(temp_pdf)
                watermark_page = watermark.pages[0]
                # 先合并页面，再添加到writer
                page.merge_page(watermark_page)
                pdf_writer.add_page(page)
    
    except Exception as e:
        raise Exception(f"处理PDF时出错: {str(e)}")
    
    finally:
        # 清理临时文件
        for file in os.listdir(temp_dir):
            try:
                os.remove(os.path.join(temp_dir, file))
            except:
                pass
        try:
            os.rmdir(temp_dir)
        except:
            pass
    
    # 保存结果
    try:
        with open(output_path, 'wb') as output_file:
            pdf_writer.write(output_file)
    except PermissionError:
        raise PermissionError(f"无法写入输出文件: {output_path}")
    except Exception as e:
        raise Exception(f"保存PDF时出错: {str(e)}")

def main():
    """主函数"""
    print("PDF页眉添加工具")
    print("-" * 20)
    
    try:
        input_file = input("请输入源PDF文件路径（直接回车使用source.pdf）: ").strip()
        if not input_file:
            input_file = "source.pdf"
        
        output_file = input("请输入目标PDF文件路径（直接回车使用当前时间）: ").strip()
        if not output_file:
            current_time = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_file = f"{current_time}.pdf"
        
        header_text = input("请输入页眉文字（直接回车使用默认值）: ").strip()
        
        try:
            if header_text:
                add_header_to_pdf(input_file, output_file, header_text)
            else:
                add_header_to_pdf(input_file, output_file)
            print(f"处理完成！文件已保存至: {output_file}")
        except Exception as e:
            print(f"错误：{str(e)}")
            
    except KeyboardInterrupt:
        print("\n程序已被用户中断")
    except Exception as e:
        print(f"发生未预期的错误：{str(e)}")

if __name__ == '__main__':
    main()