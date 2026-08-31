# -*- coding: utf-8 -*-
"""Generate "Time Recorder 使用手册.pdf" from the in-app manual content."""
import os

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.cidfonts import UnicodeCIDFont
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (HRFlowable, Paragraph, SimpleDocTemplate,
                                Spacer)

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Time Recorder 使用手册.pdf")

# ---------- 字体：优先微软雅黑（Windows），失败则退回 STSong-Light ----------
FONT_NAME = None
FONT_BOLD = None
try:
    if os.path.exists("C:/Windows/Fonts/msyh.ttc"):
        pdfmetrics.registerFont(TTFont("MSYH", "C:/Windows/Fonts/msyh.ttc", subfontIndex=0))
        pdfmetrics.registerFont(TTFont("MSYHBD", "C:/Windows/Fonts/msyhbd.ttc", subfontIndex=0))
        FONT_NAME, FONT_BOLD = "MSYH", "MSYHBD"
except Exception:
    pass
if FONT_NAME is None:
    pdfmetrics.registerFont(UnicodeCIDFont("STSong-Light"))
    FONT_NAME = "STSong-Light"
    FONT_BOLD = "STSong-Light"

ACCENT = colors.HexColor("#3B82F6")
TEXT = colors.HexColor("#1F2937")
SOFT = colors.HexColor("#6B7280")
LIGHT_BG = colors.HexColor("#EEF4FF")

# ---------- 样式 ----------
def st(name, **kw):
    base = dict(fontName=FONT_NAME, fontSize=10.5, leading=17, textColor=TEXT, alignment=TA_LEFT)
    base.update(kw)
    return ParagraphStyle(name, **base)

S_TITLE = st("title", fontName=FONT_BOLD, fontSize=24, leading=32, textColor=ACCENT, alignment=1)
S_SUB = st("sub", fontSize=11, leading=17, textColor=SOFT, alignment=1)
S_INTRO = st("intro", fontSize=11, leading=19)
S_H = st("h", fontName=FONT_BOLD, fontSize=13.5, leading=20, textColor=ACCENT, spaceBefore=6, spaceAfter=2)
S_LI = st("li", fontSize=10.5, leading=17, leftIndent=14, bulletIndent=2, spaceAfter=3)
S_TIP = st("tip", fontName=FONT_BOLD, fontSize=10.5, leading=17, textColor=colors.HexColor("#B45309"))

# ---------- 内容（与应用内手册完全一致） ----------
INTRO = ("欢迎使用 Time Recorder！这是一个帮你记录时间、安排清单、做每日复盘的小工具。"
         "数据保存在云端，电脑和手机登录同一账号即可同步。下面按页面介绍每个功能怎么用。")

SECTIONS = [
    ("⏱ 计时（主页）", [
        "<b>开始 / 停止</b>：点「开始计时」记一段时长，再点一次「停止」并保存为一条记录。",
        "<b>正计时 / 倒计时</b>：顶部可切换。倒计时需填时长，下方预设可直接选 <b>25 min / 45 min / 1 h / 1.5 h / 2 h</b>。",
        "<b>精确到秒</b>：时长一律按「分 + 秒」填写，记录也按秒显示（如 10分12秒）。",
        "<b>目标时长</b>（正计时下）：勾选「设定目标时长」可设目标，到点会弹提醒；勾选「到点自动停止并记录」则自动停表保存。",
        "<b>暂停 / 继续</b>：计时中可暂停，暂停时不保存，回来可继续。",
        "<b>单次上限 10 小时</b>：到点自动停止并记录。",
        "计时前需先在「📝 每日清单」中安排任务，计时页的「选择任务」下拉框会自动列出<b>今日清单</b>里的任务。",
    ]),
    ("📝 清单", [
        "顶部选<b>日期</b>，为该日安排任务。字段（内容 / 标签 / 详细时间 / 重要程度）<b>全部可选填</b>。",
        "重要程度分<b>高 / 中 / 低</b>，分别用 ●红 ●橙 ●黄 标注。",
        "<b>排序</b>：按「重要程度」整体排序；按「任务标签」则先分组、组内再按重要程度排。",
        "已勾选「完成」的项会<b>沉到列表底部</b>，以更淡的样式折叠显示，上方有「已完成 · N」分隔线。",
        "<b>右键</b>清单项可弹出菜单：开始计时 / 标记完成 / 删除。选「开始计时」会自动跳到计时页并定位该任务。",
        "<b>完成状态双向同步</b>：清单勾选完成后，计时页同名任务也会同步完成；反之在计时页完成任务，清单对应项也会同步完成。",
    ]),
    ("📋 历史", [
        "按 <b>今日 / 昨日 / 本周 / 本月 / 全部</b> 筛选记录，展示任务、标签、时长、日期。",
        "记录很多时自动<b>分页</b>（每页 50 条），底部可翻页。",
        "点「删除」可移除某条记录（不可恢复）。",
    ]),
    ("📊 统计", [
        "顶部显示<b>今日 / 本周 / 累计</b>总时长。",
        "<b>热力图</b>：近 10 周每天投入时长；<b>趋势图</b>：近 14 天时长变化。",
        "<b>连续打卡</b>：连续有记录的天数会显示「🔥 连续学习 X 天」。",
        "<b>查看某天复盘</b>：选日期点按钮，弹出那天的扇形图复盘。",
        "<b>每日任务看板</b>：选日期展示该日<b>清单</b>的「完成率环形图」与「优先级分布条形图（高/中/低）」。",
    ]),
    ("🌙 每日复盘", [
        "在你<b>当天首次登入</b>网址时，立即弹出昨日的时间复盘弹窗：扇形图（按事件）+ 按标签 / 事件时长汇总。例：次日 6:30 或 9:30 登入都会立刻弹出，不再依赖固定 8:00。",
        "复盘弹窗还带一张 <b>🕐 昨日 24 小时时间轴</b>：按真实起止时间把每段记录铺在 24 小时刻度上，彩色片段即对应任务，片段上标注任务名与持续时长。",
        "前一天<b>没有记录则不弹</b>。弹窗点「知道了」或点遮罩即可关闭。",
        "想随时回看某天，去「统计」页用「查看某天复盘」即可。",
    ]),
    ("☁ 云端同步 & 多设备", [
        "数据存在云端（Supabase），<b>电脑和手机用同一网址、同一账号</b>登录即同步。",
        "手机：浏览器打开本网址 → 登录同一用户名密码 → 数据自动过来。",
        "<b>分享给同学</b>：直接把网址发给他，让他自己注册账号即可（数据各自隔离，互不可见）。",
    ]),
    ("⚙️ 设置", [
        "<b>学习提醒</b>：设定时间，到点弹窗提醒（可开浏览器通知）。",
        "<b>🌗 深色模式</b>：开关即时切换整站深色/浅色，状态自动保存。",
        "<b>导出</b>：CSV（Excel 可打开）或完整 JSON 备份；<b>导入</b>：恢复 JSON 备份。",
        "<b>清空数据</b>：删除本账号全部任务 + 记录 + 清单（含云端）。",
        "<b>🤖 AI 助手配置</b>：填写 DashScope（阿里云百炼）API Key / 模型（默认 qwen3.8-max）即可，默认直连 DashScope；如需走自建后端代理，可填「后端代理地址」。",
        "<b>同步诊断</b>：对云端连通性、登录态、读取、写入、实时订阅做一次自检，便于排查跨设备不同步。",
    ]),
    ("🤖 AI 助手", [
        "先在「设置」页填写 <b>API Key / 模型</b>（默认直连 DashScope，密钥仅存本机；也可选填自建后端代理地址）。点击「测试连接」可一键验证 Key 是否有效。",
        "<b>生成学习计划</b>：输入目标（如「两周掌握微积分」），AI 拆成 3–5 个任务，确认后一键存入「任务」。",
        "<b>解析文献</b>：粘贴文本或上传 PDF / 文本文件，AI 输出<b>内容摘要、关键概念、学习建议、难点分析</b>；得到结果后可继续追问深化。",
        "<b>翻译</b>：输入文本并选择目标语言即可翻译；支持多轮追问。",
        "<b>🔍 信息聚合搜索</b>：只需输入一个简单问题，系统会基于 <b>BROKE 框架</b>自动补全背景、赋予专业角色、明确目标与输出标准，再聚合相关信息作答；答复后可追加指令动态优化（Evolve）。",
        "<b>导出为 HTML</b>：翻译、解析文献、信息聚合搜索均支持将当前完整对话记录导出为 HTML 文件。",
        "调用时显示加载态；报错会提示「API Key 无效」「网络超时」等友好信息。",
    ]),
]

TIP = "💡 小提示：复盘在你当天首次登入网址时弹出（需网页处于打开 / 登录状态），同一天重复进入不会重复弹。"

# ---------- 组装 PDF ----------
doc = SimpleDocTemplate(
    OUT, pagesize=A4,
    leftMargin=22*mm, rightMargin=22*mm, topMargin=20*mm, bottomMargin=18*mm,
    title="Time Recorder 使用手册", author="Time Recorder",
)

def footer(canvas, doc_):
    canvas.saveState()
    canvas.setFont(FONT_NAME, 8.5)
    canvas.setFillColor(SOFT)
    canvas.drawCentredString(A4[0] / 2, 10*mm, f"Time Recorder 使用手册 · 第 {doc_.page} 页")
    canvas.restoreState()

story = []
story.append(Paragraph("Time Recorder 使用手册", S_TITLE))
story.append(Spacer(1, 4))
story.append(Paragraph("记录时间 · 安排清单 · 每日复盘 · 云端同步", S_SUB))
story.append(Spacer(1, 12))
story.append(HRFlowable(width="100%", thickness=1.2, color=ACCENT, spaceAfter=14))
story.append(Paragraph(INTRO, S_INTRO))
story.append(Spacer(1, 8))

for i, (title, bullets) in enumerate(SECTIONS, 1):
    story.append(Paragraph(f"{i}. {title}", S_H))
    for b in bullets:
        story.append(Paragraph(b, S_LI, bulletText="•"))
    story.append(Spacer(1, 8))

story.append(HRFlowable(width="100%", thickness=0.8, color=colors.HexColor("#D6DEEF"), spaceBefore=6, spaceAfter=8))
story.append(Paragraph(TIP, S_TIP))

doc.build(story, onFirstPage=footer, onLaterPages=footer)
print("PDF_OK:", OUT)
