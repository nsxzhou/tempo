// ============================================================
// sync.ts — 推送任务到 Supabase + 写回 custom-tempo-id
// ============================================================

import { createTaskFromSiyuan } from './api';
import {
  hasTempoId,
  writeTempoId,
  type UncompletedTask,
  type ScanResult,
} from './scanner';

/** 同步单个任务到 Supabase 并写回 custom-tempo-id */
export async function syncTask(task: UncompletedTask): Promise<boolean> {
  // 1. 检查是否已有 custom-tempo-id（幂等）
  const alreadySynced = await hasTempoId(task.blockId);
  if (alreadySynced) {
    return false; // 已同步，跳过
  }

  // 2. 调用 RPC 创建任务
  const taskId = await createTaskFromSiyuan(
    task.title,
    task.blockId,
    null, // description
    null, // due_date
    0     // priority
  );

  // 3. 写回 custom-tempo-id 到思源块
  await writeTempoId(task.blockId, taskId);

  return true; // 新导入
}

/** 批量同步任务 */
export async function syncTasks(tasks: UncompletedTask[]): Promise<ScanResult> {
  const result: ScanResult = {
    total: tasks.length,
    imported: 0,
    skipped: 0,
    errors: [],
  };

  for (const task of tasks) {
    try {
      const imported = await syncTask(task);
      if (imported) {
        result.imported++;
      } else {
        result.skipped++;
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      result.errors.push(`「${task.title}」: ${message}`);
      // 网络错误不影响已成功导入的任务
    }
  }

  return result;
}
