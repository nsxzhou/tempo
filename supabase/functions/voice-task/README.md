# voice-task Edge Function

Proxy boundary for the Tempo voice task creation spike.

## Request

Use either `multipart/form-data`:

```text
audio=<file>
```

or JSON for simple test clients:

```json
{
  "audio_base64": "<base64 encoded m4a/mp4 audio>"
}
```

## Response

```json
{
  "title": "提交设计稿",
  "description": "识别内容: 明天下午三点提交设计稿，优先级高",
  "due_date": "2026-06-19T15:00:00.000+08:00",
  "priority": 2,
  "confidence": 0.86,
  "raw_transcript": "明天下午三点提交设计稿，优先级高"
}
```

`priority` uses the existing Tempo task scale: `0` none, `1` P0, `2` P1, `3` P2, `4` P3.

## Environment

- `VOICE_TASK_MOCK=true` returns a fixed response without external calls.
- `VOLCENGINE_ASR_ENDPOINT` is the enabled Volcengine ASR HTTP endpoint for the account/product being tested.
- `VOLCENGINE_ASR_APP_KEY` is sent as `X-Api-App-Key`.
- `VOLCENGINE_ASR_ACCESS_TOKEN` is sent as `Authorization: Bearer ...`.
- `DOUBAO_ENDPOINT` defaults to `https://ark.cn-beijing.volces.com/api/v3/chat/completions`.
- `DOUBAO_API_KEY` authorizes the Doubao model call.
- `DOUBAO_MODEL` is the Ark/Doubao model id.

The mobile app should call this function, not Volcengine or Doubao directly.
