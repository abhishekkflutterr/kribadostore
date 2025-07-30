import 'package:flutter/material.dart';
import 'package:kribadostore/constants/ColorConstants.dart';
//abhsihek edit

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final String? errorText;
  final bool showRadio;
  final VoidCallback? onClearCacheAndRefresh;
  final List<String>? radioValues;
  final bool filterRadioValues;
  final String control;


  const CustomTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.errorText,
    this.showRadio = false,
    this.onClearCacheAndRefresh,
    this.filterRadioValues = false,
    this.radioValues,
    this.control = "male",
  });


  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}


class _CustomTextFieldState extends State<CustomTextField> {
  static final Map<String, int> _hintCountMap = {};


  @override
  void initState() {
    super.initState();
    _checkAndClearCache();
  }


  void _checkAndClearCache() {
    if (_hintCountMap.containsKey(widget.hintText)) {
      _hintCountMap[widget.hintText] = _hintCountMap[widget.hintText]! + 1;
    } else {
      _hintCountMap[widget.hintText] = 1;
    }


    if (_hintCountMap[widget.hintText]! > 1 && widget.hintText == "Gender") {
      _clearCacheAndRefresh();
    }
  }


  void _clearCacheAndRefresh() {
    setState(() {
      _hintCountMap.clear();
    });
    if (widget.onClearCacheAndRefresh != null) {
      widget.onClearCacheAndRefresh!();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorConstants.colorR8,
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.hintText == 'Age')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      color: ColorConstants.colorR8,
                      width: 210,
                      // Set specific width for the age input field
                      child: TextFormField(
                        controller: widget.controller,
                        obscureText: widget.obscureText,
                        keyboardType: widget.keyboardType,
                        textCapitalization: TextCapitalization.words, // Capitalize initials
                        textInputAction: TextInputAction.next, // Move to the next field on "Done" button press
                        decoration: InputDecoration(
                          labelText: widget.hintText,
                          filled: true,
                          fillColor: ColorConstants.colorR8, // Adjust opacity here
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: BorderSide(
                              color: ColorConstants.lightGrey,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: BorderSide(
                              color: ColorConstants.lightGrey.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: BorderSide(
                              color: ColorConstants.lightGrey,
                            ),
                          ),
                          hintStyle: TextStyle(
                            color: Colors.black,
                            fontFamily: 'Quicksand-SemiBold',
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 10),

                    Container(
                      decoration: ShapeDecoration(
                          color: ColorConstants.newGreenColor,
                          shape: RoundedRectangleBorder (
                              borderRadius: BorderRadius.circular(10.0),
                              side: BorderSide(
                                color: ColorConstants.newGreenColor,

                              )
                          )
                      ),
                      child: IconButton(
                        icon: Icon(Icons.remove_circle_outline,color: ColorConstants.colorR9,),
                        onPressed: () {
                          int currentValue = int.tryParse(widget.controller.text) ?? 0;
                          if (currentValue > 0) {
                            widget.controller.text = (currentValue - 1).toString();
                          }
                        },
                      ),
                    ),

                    SizedBox(width: 10,),
                    Container(
                      decoration: ShapeDecoration(
                          color: ColorConstants.newGreenColor,
                          shape: RoundedRectangleBorder (
                              borderRadius: BorderRadius.circular(10.0),
                              side: BorderSide(
                                color: ColorConstants.newGreenColor,

                              )
                          )
                      ),
                      child: IconButton(
                        color: ColorConstants.newGreenColor,
                        icon: Icon(Icons.add_circle_outline,color: ColorConstants.colorR9,),
                        onPressed: () {
                          int currentValue = int.tryParse(widget.controller.text) ?? 0;
                          widget.controller.text = (currentValue + 1).toString();
                        },
                      ),
                    ),
                  ],
                ),
                if (widget.errorText?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      widget.errorText!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16.0,
                        fontFamily: 'Quicksand-SemiBold',
                        fontWeight: FontWeight.w400, // or FontWeight.normal for regular
                      ),
                    ),
                  ),
              ],
            )
          else if (widget.hintText == 'Gender')

            Card(
              color: ColorConstants.colorR8,
              clipBehavior: Clip.none,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
                      child: Text(
                        'Gender',
                        style: TextStyle(
                          fontFamily: 'Quicksand-SemiBold',
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      height: 150,
                      child: CustomRadioButton(
                        icons: widget.filterRadioValues
                            ? widget.radioValues!
                            .asMap()
                            .entries
                            .where((entry) =>
                        entry.value.trim().toLowerCase() !=
                            widget.control.toLowerCase())
                            .map((entry) => [Icons.male, Icons.female][entry.key])
                            .toList()
                            : [Icons.male, Icons.female],
                        values: widget.filterRadioValues
                            ? (widget.radioValues
                            ?.where((value) =>
                        value.trim().toLowerCase() !=
                            widget.control.toLowerCase())
                            .toList() ??
                            [])
                            : (widget.radioValues ?? ['Male', 'Female']),
                        groupValue: widget.controller.text,
                        onChanged: (String? value) {
                          setState(() {
                            widget.controller.text = value!;
                          });
                        },
                        errorText: widget.errorText,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            TextFormField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: widget.hintText,
                filled: true,
                fillColor: ColorConstants.cultured.withOpacity(0.1),
                errorText: widget.errorText?.isNotEmpty == true
                    ? widget.errorText
                    : null,
                errorStyle: TextStyle(
                  fontSize: 16.0,
                  fontFamily: 'Quicksand-SemiBold',
                  fontWeight: FontWeight.w400,
                  color: Colors.red,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: BorderSide(
                    color: ColorConstants.lightGrey,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: BorderSide(
                    color: ColorConstants.lightGrey.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: BorderSide(
                    color: ColorConstants.lightGrey,
                  ),
                ),
                hintStyle: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontFamily: 'Quicksand-SemiBold',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}


class CustomRadioButton extends StatefulWidget {
  final List<IconData> icons;
  final List<String> values;
  final String? groupValue;
  final void Function(String?)? onChanged;
  final String? errorText;


  const CustomRadioButton({
    required this.icons,
    required this.values,
    required this.groupValue,
    required this.onChanged,
    this.errorText,
  });


  @override
  _CustomRadioButtonState createState() => _CustomRadioButtonState();
}


class _CustomRadioButtonState extends State<CustomRadioButton> {
  late String? _groupValue;
  bool _showError = false;


  @override
  void initState() {
    super.initState();
    _groupValue = widget.groupValue;
    _showError = _groupValue == null || _groupValue!.isEmpty;
  }


  void _onToggle(String? value) {
    setState(() {
      _groupValue = value;
      _showError = value == null || value.isEmpty;
    });
    if (widget.onChanged != null) {
      widget.onChanged!(value);
    }
  }


  @override
  Widget build(BuildContext context) {
    // assert(widget.icons.length == widget.values.length,
    // 'Icons and values must have the same length');


    return Column(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(widget.values.length, (int index) {
            bool isSelected = _groupValue == widget.values[index];
            return GestureDetector(
              onTap: () => _onToggle(widget.values[index]),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: ColorConstants.lightGrey),
                ),
                margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 25),
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icons[index],
                      color: isSelected ? Colors.white : Colors.black,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      widget.values[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Quicksand-SemiBold',
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        if (_showError && widget.errorText != null)
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              widget.errorText!,
              style: TextStyle(
                color: Colors.red,
                fontSize: 16.0,
                fontFamily: 'Quicksand-SemiBold',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}



