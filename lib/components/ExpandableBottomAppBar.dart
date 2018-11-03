import 'package:flutter/material.dart';
class ExpandableBottomAppBar extends StatefulWidget {

  final Widget header;
  final Widget body;
  final bool hasAppbar;
  final Duration animationDuration;
  final BuildContext parentContext;
  final Color safeAreaPaddingColor;

  ExpandableBottomAppBar({
    Key key,
    this.body,
    this.header,
    this.safeAreaPaddingColor = Colors.white,
    this.parentContext,
    this.hasAppbar = true,
    this.animationDuration = const Duration(milliseconds: 500)
  }): super(key: key);

  @override
  ExpandableBottomAppBarState createState() => new ExpandableBottomAppBarState();
}

class ExpandableBottomAppBarState extends State<ExpandableBottomAppBar> with TickerProviderStateMixin{

  bool isExpanded = false;
  Animation<double> doubleAnimation;
  AnimationController controller;
  Animation curve;


  @override
  void initState() {
    super.initState();
    controller = new AnimationController(
        duration: widget.animationDuration, vsync: this);
    controller.addListener((){setState(() {});});
    final Tween doubleTween = new Tween<double>(begin: 0.0, end: 1.0);
    curve = new CurvedAnimation(parent: controller, curve: Curves.easeOut);
    doubleAnimation = doubleTween.animate(curve);
  }

  setExpanded(bool expand, {VoidCallback onComplete})
  {
    if(mounted) {
      if (expand && !isExpanded){
        isExpanded = expand;
        controller.forward().whenComplete(onComplete ?? (){});

      }
      else if (!expand && isExpanded) {
        controller.reverse().whenComplete((){
          isExpanded = expand;
          if(onComplete != null)
            onComplete();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double appbarHeight = widget.hasAppbar ? kToolbarHeight : 0.0;
    double maxHeight = MediaQuery.of(context).size.height - appbarHeight;
    MediaQueryData media;
    if(widget.parentContext != null)
      media = MediaQuery.of(widget.parentContext);
    return new Container(
      child: new Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        new Container(
          padding: new EdgeInsets.only(bottom: kToolbarHeight),
          height: doubleAnimation.value * maxHeight,
          child: isExpanded ? widget.body : new Container(),
        ),

        new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            widget.header,
            new Container(
              height: MediaQuery.of(context).padding.bottom,
              color: widget.safeAreaPaddingColor,
            ),
          ],
        ),
      ],
    ));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
