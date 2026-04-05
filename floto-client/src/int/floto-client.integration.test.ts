import { FlotoClient } from '@floto/client';

const client = new FlotoClient();

describe('ping', () => {
  it('responds with version when successful', async () => {
    const response = await client.ping();

    expect(response).toBeDefined();
    expect(response).toEqual(expect.any(String));
  });
});
