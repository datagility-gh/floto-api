const baseUrl = process.env.FLOTO_API_BASE || 'floto.io/';

export class FlotoClient {
  private async get(path: string) {
    const init = {
      method: 'GET'
    };

    return await this.doFetch(path, init);
  }

  private async doFetch(path: string, init?: RequestInit) {

    if(init)
    {
      init.headers = {
        'floto-sub-key': process.env.FLOTO_API_KEY || ''
      }
    }

    const url = `${baseUrl}${path}`

    const response = await fetch(url, init);

    const result = new FetchResult(response.status);

    result.content = await response.text();

    return result;
  }

  async ping(): Promise<string> {
    const response = await this.get('ping');

    if (response.isError) {
      throw new Error(`HTTP ${response.status}`);
    }

    return String(response.content);
  }
}

class FetchResult {
  private HTTP_BAD_REQUEST = 400;

  private _status: number;
  content: unknown;

  public get status(): number {
    return this._status;
  }

  public get isError(): boolean {
    return this._status >= this.HTTP_BAD_REQUEST;
  }

  constructor(status: number) {
    this._status = status;
  }
}
