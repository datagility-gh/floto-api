import { FlotoClient } from './floto-client';

beforeEach(() => {
  global.fetch = jest.fn();
});

afterEach(() => {
  jest.clearAllMocks();
});

describe('ping', () => {
  it('responds with version when successful', async () => {
    const expectedVersion = 'someVersion';

    global.fetch = jest.fn().mockResolvedValue({
      status: 200,
      text: () => Promise.resolve(expectedVersion)
    });

    const client = new FlotoClient();
    const response = await client.ping();

    expect(response).toEqual(expectedVersion);
  });

  it('throws exception when http error returned', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      status: 400
    });

    const client = new FlotoClient();
    expect(client.ping()).rejects.toThrow();
  });

  it('throws exception when other exception occurs', async () => {
    global.fetch = jest.fn().mockRejectedValue(
      new Error("Network error")
    );

    const client = new FlotoClient();
    expect(client.ping()).rejects.toThrow();
  });
});
