import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'TimeRecorder';

export function logInfo(msg: string): void {
  hilog.info(DOMAIN, TAG, '%{public}s', msg);
}

export function logError(msg: string): void {
  hilog.error(DOMAIN, TAG, '%{public}s', msg);
}
