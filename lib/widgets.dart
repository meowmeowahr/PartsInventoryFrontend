import 'package:flutter/material.dart';

class NumberSpinner extends StatelessWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final String? title;
  final String suffix;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const NumberSpinner({
    super.key,
    required this.value,
    this.minValue = 0,
    this.maxValue = 100,
    this.title,
    this.suffix = "",
    this.enabled = true,
    required this.onChanged,
  });

  void _increment() {
    if (value < maxValue) {
      onChanged(value + 1);
    }
  }

  void _decrement() {
    if (value > minValue) {
      onChanged(value - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          title != null
              ? Text(
                  title!,
                  style: TextStyle(
                      fontSize: 22,
                      color: Theme.of(context).colorScheme.primary),
                )
              : const SizedBox(),
          enabled
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: _decrement,
                        style: ElevatedButton.styleFrom(
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30.0, vertical: 30.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: const Icon(Icons.remove),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          '$value$suffix',
                          style: const TextStyle(fontSize: 24.0),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _increment,
                        style: ElevatedButton.styleFrom(
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30.0, vertical: 30.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Disabled",
                    style: TextStyle(
                        fontSize: 22,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
        ],
      ),
    );
  }
}

class CustomSearchBar extends StatelessWidget {
  final Function(String) onChanged;

  const CustomSearchBar({required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        hintText: 'Search...',
        border: InputBorder.none,
        prefixIcon: const Icon(Icons.search),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
      ),
    );
  }
}

class ColumnBuilder extends StatelessWidget {
  final IndexedWidgetBuilder itemBuilder;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final int itemCount;

  const ColumnBuilder({
    super.key,
    required this.itemBuilder,
    required this.itemCount,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      children: List.generate(itemCount, (index) => itemBuilder(context, index))
          .toList(),
    );
  }
}
