import 'package:flutter/material.dart';

import 'package:leet_block/main.dart';
import 'package:leet_block/providers/leet_block_provider.dart';

Widget buildTestApp(LeetBlockProvider provider) {
  return LeetBlockApp(provider: provider, autoStartBlockerService: false);
}
