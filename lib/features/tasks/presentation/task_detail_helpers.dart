String taskDetailSourceTag(String source) {
  switch (source) {
    case 'voice':
      return '语音';
    case 'siyuan':
      return '思源';
    case 'ai':
      return 'AI';
    default:
      return '文本';
  }
}

String taskDetailSourceLabel(String source) {
  switch (source) {
    case 'voice':
      return '语音 🎤';
    case 'siyuan':
      return '思源笔记';
    case 'ai':
      return 'AI 排期';
    default:
      return '文本输入';
  }
}
