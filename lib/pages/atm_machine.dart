import 'package:flutter/material.dart';
import 'package:wallet_animation/main.dart';
import 'package:wallet_animation/pages/receipt_page.dart';

class AtmMachine extends StatefulWidget {
  const AtmMachine({super.key});

  @override
  State<AtmMachine> createState() => _AtmMachineState();
}

class _AtmMachineState extends State<AtmMachine> with TickerProviderStateMixin {
  late AnimationController _atmController;
  late AnimationController _controller;
  late AnimationController _cardInsertController;

  late Animation<double> _atmAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Card insertion animation controllers
  late Animation<Offset> _cardOffsetAnimation;
  bool _isCardInserting = false;
  bool _isCardInserted = false;
  bool _isReceiptVisible = false;
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, 1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // ATM slide down animation
    _atmController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _atmAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _atmController, curve: Curves.ease));

    _buttonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _atmController, curve: Curves.ease));

    // Card insertion animation setup
    _cardInsertController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _cardOffsetAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-60.0, 0.0),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-60.0, 0.0),
          end: const Offset(-60.0, 0.0),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-60.0, 0.0),
          end: const Offset(-60.0, -240.0),
        ).chain(CurveTween(curve: Curves.fastOutSlowIn)),
        weight: 20.0,
      ),
    ]).animate(_cardInsertController);

    Future.delayed(const Duration(milliseconds: 800), () async {
      await _atmController.forward();
      AtmScreenTextChange("welcome");

      Future.delayed(const Duration(milliseconds: 2500), () async {
        AtmScreenTextChange("insertCard");
      });
    });
  }

  void AtmScreenTextChange(text) async {
    await _controller.forward();
    setState(() {
      atmStatus = text;
    });
    _controller.reverse();
  }

  Future<void> _startCardInsertAnimation() async {
    if (!_isCardInserted) {
      setState(() {
        _isCardInserting = true;
      });

      await _cardInsertController.forward();

      Future.delayed(const Duration(milliseconds: 1000), () async {
        _isCardInserted = true;
        AtmScreenTextChange("enterAmount");
      });
    } else {
      AtmScreenTextChange("processing");

      Future.delayed(const Duration(milliseconds: 2500), () {
        AtmScreenTextChange("success");
      });

      Future.delayed(const Duration(milliseconds: 4500), () {
        AtmScreenTextChange("receipt");
        _isReceiptVisible = true;
        setState(() {});
      });

      Future.delayed(const Duration(milliseconds: 7000), () {
        AtmScreenTextChange("thankYou");
      });

      Future.delayed(const Duration(milliseconds: 9000), () {
        _atmController.reverse();
        setState(() {});
      });

      Future.delayed(const Duration(milliseconds: 9500), () {
        Navigator.of(
          context,
        ).push(CustomPageRoute(child: const ReceiptScreen()));
      });
    }
  }

  @override
  void dispose() {
    _atmController.dispose();
    _cardInsertController.dispose();
    super.dispose();
  }

  String atmStatus = "";
  int selectedAmount = 0;
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  top: 20,
                  left: _isCardInserting ? -20 : -50,
                  child: AnimatedBuilder(
                    animation: _atmAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          _atmAnimation.value * size.height * 0.8,
                        ),
                        child: child,
                      );
                    },
                    child: SizedBox(
                      height: size.height * 0.8,
                      child: Image.asset('assets/atm.png'),
                    ),
                  ),
                ),

                // Card with animation
                Positioned(
                  right: -15,
                  top: size.height * 0.6,
                  child: AnimatedBuilder(
                    animation: _cardOffsetAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: _cardOffsetAnimation.value,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 2500),
                          width: 114,
                          height:
                              _cardOffsetAnimation.value.dy < -239 ? 0 : 160,
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.bottomCenter,
                              maxHeight: 160,
                              child: Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  height:
                                      _cardOffsetAnimation.value.dy < 0
                                          ? 70
                                          : 160,
                                  child: child,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'card_animation',
                      child: RotationTransition(
                        turns: const AlwaysStoppedAnimation(0.25),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Image.asset(
                            'assets/background-removed.png',
                            height: 160,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                //recipe
                Positioned(
                  top: size.height * 0.21,
                  right: 86,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 2000),
                    width: 30,
                    height: _isReceiptVisible ? 40 : 0,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.bottomCenter,
                        maxHeight: 40,
                        child: Transform.translate(
                          offset: Offset(0, _isReceiptVisible ? 0 : 40),
                          child: Hero(
                            tag: 'receipt',
                            child: Image.asset('assets/receipt.png'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  top: size.height * 0.21,
                  left: _isCardInserting ? 95 : 65,
                  child: _BuildAtmScreen(atmStatus),
                ),

                Positioned(
                  bottom: 0,
                  left: 30,
                  child:
                      _isCardInserted
                          ? TweenAnimationBuilder(
                            duration: Duration(milliseconds: 400),
                            tween: Tween<Offset>(
                              begin: const Offset(-1, 0),
                              end: const Offset(0, 0),
                            ),
                            builder: (context, Offset offset, child) {
                              return Transform.translate(
                                offset: offset * 300,
                                child: child,
                              );
                            },
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(
                                      bottom: 10,
                                      right: 5,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          selectedAmount = 100;
                                          setState(() {});
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 15,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              0.1,
                                            ),
                                            border: Border.all(
                                              color: Colors.green.withOpacity(
                                                0.3,
                                              ),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '\$100',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green[700],
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 14,
                                                color: Colors.green[700],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  Container(
                                    margin: const EdgeInsets.only(
                                      bottom: 10,
                                      right: 5,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          selectedAmount = 500;
                                          setState(() {});
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 15,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              0.1,
                                            ),
                                            border: Border.all(
                                              color: Colors.green.withOpacity(
                                                0.3,
                                              ),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '\$500',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green[700],
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 14,
                                                color: Colors.green[700],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  Container(
                                    margin: const EdgeInsets.only(
                                      bottom: 10,
                                      right: 5,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          selectedAmount = 1000;
                                          setState(() {});
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 15,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              0.1,
                                            ),
                                            border: Border.all(
                                              color: Colors.green.withOpacity(
                                                0.3,
                                              ),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '\$1000',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green[700],
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 14,
                                                color: Colors.green[700],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          : SizedBox(),
                ),
              ],
            ),
          ),

          // Button with animation using existing atmAnimation
          AnimatedBuilder(
            animation: _buttonAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _buttonAnimation.value * 200),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _startCardInsertAnimation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _BuildAtmScreen(type) {
    String text = AtmStatus[type] ?? "";
    return Opacity(
      opacity:
          _atmController.status == AnimationStatus.completed &&
                  !_atmController.isAnimating
              ? 1
              : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          type == "enterAmount"
              ? SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    "\$$selectedAmount",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
              : SizedBox(),
        ],
      ),
    );
  }

  var AtmStatus = {
    "welcome": "Welcome",
    "insertCard": "Insert Card",
    "enterAmount": "Enter Amount",
    "processing": "Processing",
    "success": "Success",
    "receipt": "Receipt",
    "thankYou": "Thank You",
  };
}
