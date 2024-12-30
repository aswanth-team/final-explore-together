void main() {

  String formatCount(int count) {
    if (count >= 1000000000) {
      double formatted = count / 1000000000;
      String result = formatted
          .toStringAsFixed(formatted.truncateToDouble() == formatted ? 0 : 2);
      return result.endsWith('.00')
          ? '${result.substring(0, result.length - 3)}B'
          : '${result}B';
    } else if (count >= 1000000) {
      double formatted = count / 1000000;
      String result = formatted
          .toStringAsFixed(formatted.truncateToDouble() == formatted ? 0 : 2);
      return result.endsWith('.00')
          ? '${result.substring(0, result.length - 3)}M'
          : '${result}M';
    } else if (count >= 1000) {
      double formatted = count / 1000;
      String result = formatted
          .toStringAsFixed(formatted.truncateToDouble() == formatted ? 0 : 2);
      return result.endsWith('.00')
          ? '${result.substring(0, result.length - 3)}K'
          : '${result}K';
    }
    return count.toString();
  }

  print(formatCount(999)); 
  print(formatCount(1001)); 
  print(formatCount(1010)); 
  print(formatCount(1500)); 
  print(formatCount(1000000)); 
  print(formatCount(1000000000)); 
}
