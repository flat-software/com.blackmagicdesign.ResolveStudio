export enum Branch {
  STABLE = "stable",
  BETA = "beta",
}

export interface Version {
  major: number;
  minor: number;
  patch: number;
  build: number;
  beta?: number;
  releaseId: string;
  downloadId: string;
}
