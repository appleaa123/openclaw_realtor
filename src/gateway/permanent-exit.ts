/** Thrown by a channel task to signal a permanent, non-retryable exit (e.g. 401 logged out). */
export class PermanentChannelExit extends Error {
  constructor(reason: string) {
    super(reason);
    this.name = "PermanentChannelExit";
  }
}
