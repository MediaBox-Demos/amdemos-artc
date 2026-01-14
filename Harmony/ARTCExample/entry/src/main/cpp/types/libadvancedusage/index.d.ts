export class OriginAudioData {
  constructor(arg: number);
  enable(enable: boolean): number;
}

export class OriginVideoData {
  constructor(arg: number);
  enable(enable: boolean): number;
  takeSnapshot(): number;
}
