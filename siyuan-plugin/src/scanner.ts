// ============================================================
// scanner.ts — 扫描当前文档任务块 + 检查 custom-tempo-id
// ============================================================

/** 思源 Kernel API 封装 */
const SIYUAN_API = '/api';

/** 调用思源 Kernel API */
async function siyuanRequest<T>(
  endpoint: string,
  data: Record<string, unknown>
): Promise<T> {
  const response = await fetch(`${SIYUAN_API}${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });

  if (!response.ok) {
    throw new Error(`思源 API 调用失败: ${response.status}`);
  }

  const result = await response.json();
  if (result.code !== 0) {
    throw new Error(result.msg || '思源 API 返回错误');
  }

  return result.data as T;
}

/** 获取当前打开的文档 ID */
export async function getCurrentDocId(): Promise<string | null> {
  try {
    const response = await fetch(`${SIYUAN_API}/block/getDocInfo`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    });

    if (!response.ok) return null;

    const result = await response.json();
    if (result.code !== 0) return null;

    return result.data?.rootID ?? null;
  } catch {
    return null;
  }
}

/** 思源子块类型 */
interface SiyuanBlock {
  id: string;
  type: string; // NodeListItem, NodeParagraph, etc.
  content?: string;
  markdown?: string;
  children?: SiyuanBlock[];
}

/** 获取文档的所有子块 */
export async function getChildBlocks(docId: string): Promise<SiyuanBlock[]> {
  return siyuanRequest<SiyuanBlock[]>('/block/getChildBlocks', {
    id: docId,
  });
}

/** 获取块的自定义属性 */
export async function getBlockAttrs(
  blockId: string
): Promise<Record<string, string>> {
  return siyuanRequest<Record<string, string>>('/attr/getBlockAttrs', {
    id: blockId,
  });
}

/** 设置块的自定义属性 */
export async function setBlockAttrs(
  blockId: string,
  attrs: Record<string, string>
): Promise<void> {
  await siyuanRequest('/attr/setBlockAttrs', {
    id: blockId,
    attrs,
  });
}

/** 未完成的任务块 */
export interface UncompletedTask {
  blockId: string;
  title: string;
}

/** 从子块中提取未完成的任务列表项 */
export function extractUncompletedTasks(
  blocks: SiyuanBlock[]
): UncompletedTask[] {
  const tasks: UncompletedTask[] = [];

  function traverse(blockList: SiyuanBlock[]) {
    for (const block of blockList) {
      // NodeListItem 类型且包含 checkbox 标记
      if (block.type === 'NodeListItem' || block.type === 'NodeList') {
        const content = block.content || block.markdown || '';
        // 检查是否是未完成的任务块（☐ 或 [ ] 开头）
        if (isUncompletedTask(content)) {
          const title = extractTaskTitle(content);
          if (title.trim()) {
            tasks.push({ blockId: block.id, title });
          }
        }
      }

      // 递归处理子块
      if (block.children && block.children.length > 0) {
        traverse(block.children);
      }
    }
  }

  traverse(blocks);
  return tasks;
}

/** 判断是否是未完成的任务块 */
function isUncompletedTask(content: string): boolean {
  // 思源未完成任务标记: ☐ 或 * [ ] 或 - [ ]
  return /\* \[ \]|^- \[ \]|^☐|^\* ☐/.test(content.trim()) ||
         content.includes('☐') ||
         (content.includes('[ ]') && !content.includes('[x]'));
}

/** 从任务块内容中提取标题 */
function extractTaskTitle(content: string): string {
  // 去掉 checkbox 标记
  let title = content
    .replace(/^\* \[ \]\s*/, '')
    .replace(/^- \[ \]\s*/, '')
    .replace(/^☐\s*/, '')
    .replace(/^\* ☐\s*/, '')
    .trim();

  // 去掉 Markdown 格式标记
  title = title.replace(/\*\*/g, '').replace(/\*/g, '').replace(/`/g, '');

  return title;
}

/** 检查块是否已有 custom-tempo-id */
export async function hasTempoId(blockId: string): Promise<boolean> {
  try {
    const attrs = await getBlockAttrs(blockId);
    const tempoId = attrs['custom-tempo-id'];
    return tempoId != null && tempoId.trim() !== '';
  } catch {
    return false;
  }
}

/** 写回 custom-tempo-id 到块属性 */
export async function writeTempoId(
  blockId: string,
  taskId: string
): Promise<void> {
  await setBlockAttrs(blockId, { 'custom-tempo-id': taskId });
}

/** 扫描结果 */
export interface ScanResult {
  total: number;
  imported: number;
  skipped: number;
  errors: string[];
}
