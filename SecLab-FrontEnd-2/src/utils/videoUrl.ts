/**
 * 课程视频地址解析
 *
 * 首选本地视频：public/video/ai-01.mp4 ~ ai-10.mp4（随项目提供，无需外网）。
 * 原阿里云 OSS 桶 labsyssss 账号已停用（403 UserDisable），仅作为历史回退保留。
 *
 * 可用 VITE_OSS_BASE_URL / VITE_OSS_VIDEO_DIR 覆盖 OSS 回退地址（适合换 bucket 或迁移目录）。
 */

const DEFAULT_OSS_BASE = 'https://labsyssss.oss-cn-beijing.aliyuncs.com'
const DEFAULT_OSS_DIR = '“立心之约”中学生AI微课十讲'
const LOCAL_VIDEO_DIR = '/video'

/** OSS 上 10 讲的真实文件名（与本地原始视频一致） */
const LECTURE_FILES: Record<number, string> = {
  1: '第1讲人工智能的现状趋势与战略.mp4',
  2: '第2讲机器眼中的大千世界计算机视觉.mp4',
  3: '第3讲语言与机器的火花碰撞自然语言处理.mp4',
  4: '第4讲认知科学与AI世界的邀约认知推理.mp4',
  5: '第5讲机器自我成长进步机器学习.mp4',
  6: '第6讲未来生活离不开的伙伴智能机器人.mp4',
  7: '第7讲机器世界不孤单多智能体.mp4',
  8: '第8讲机器生活的世界物理世界仿真模拟.mp4',
  9: '第9讲舞动科技的音符人工智能音乐.mp4',
  10: '第10讲人工智能在北大.mp4'
}

function cleanBase(raw: string | undefined): string {
  return (raw || DEFAULT_OSS_BASE).replace(/\/+$/, '')
}

function cleanDir(raw: string | undefined): string {
  if (raw === undefined) return DEFAULT_OSS_DIR
  return raw.replace(/^\/+|\/+$/g, '')
}

export const OSS_BASE_URL = cleanBase(import.meta.env.VITE_OSS_BASE_URL)
export const OSS_VIDEO_DIR = cleanDir(import.meta.env.VITE_OSS_VIDEO_DIR)

function encodePath(path: string): string {
  return path.split('/').map(encodeURIComponent).join('/')
}

/** 本地视频地址：public/video/ai-NN.mp4 */
function getLocalVideoUrl(lectureNo: number | string): string {
  const no = Number(lectureNo)
  if (!Number.isInteger(no) || no < 1 || no > 10) return ''
  return `${LOCAL_VIDEO_DIR}/ai-${String(no).padStart(2, '0')}.mp4`
}

/** 拼出某一讲的视频完整 URL（本地优先） */
export function getCourseVideoUrl(lectureNo: number | string): string {
  return getLocalVideoUrl(lectureNo)
}

/** 候选地址：本地视频优先，OSS 主路径与桶根目录作为历史回退（浏览器多 <source> 自动尝试） */
export function getCourseVideoUrlCandidates(no: number | string): string[] {
  const local = getLocalVideoUrl(no)
  if (!local) return []
  const file = LECTURE_FILES[Number(no)]
  if (!file) return [local]
  const fullPath = OSS_VIDEO_DIR ? `${OSS_VIDEO_DIR}/${file}` : file
  return [local, `${OSS_BASE_URL}/${encodePath(fullPath)}`, `${OSS_BASE_URL}/${encodePath(file)}`]
}

/** 兼容历史调用：从路径里抽讲次编号 */
export function toOssVideoUrl(path: string | undefined | null): string {
  if (!path) return ''
  const match = path.match(/(\d{1,2})/)
  return match ? getCourseVideoUrl(Number(match[1])) : ''
}
