import 'package:flutter/material.dart';
import 'package:wallet_animation/main.dart';
import 'package:wallet_animation/pages/atm_machine.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _SlideController;
  late Animation<double> _animation;
  late Animation<double> _walletAnimation;
  late Animation<double> _buttonAnimation;
  double _dragOffset = 0.0;
  bool _showFirstCard = true;
  bool _showSecondCard = false;
  bool _hideBalance = false;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _SlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _walletAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(_SlideController);

    _buttonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_SlideController);

    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);

    bool cardSwitched = false;
    _animation.addListener(() {
      final progress = _animation.value / -250.0;
      if (progress >= 0.9 && !cardSwitched) {
        setState(() {
          _showFirstCard = !_showFirstCard;
          cardSwitched = true;
          Future.delayed(const Duration(milliseconds: 200), () {
            setState(() {
              _showSecondCard = !_showSecondCard;
            });
          });
        });
      }

      if (progress < 0.5) {
        cardSwitched = false;
      }
    });

    _SlideController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
      _dragOffset = _dragOffset.clamp(-150.0, 0.0);
    });
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (_dragOffset <= -120) {
      final double startOffset = _dragOffset;
      _controller.reset();

      _animation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: startOffset,
            end: -250.0,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 30.0,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: -250.0,
            end: 0.0,
          ).chain(CurveTween(curve: Curves.ease)),
          weight: 70.0,
        ),
      ]).animate(_controller);

      setState(() {
        _dragOffset = 0.0;
      });

      await _controller.forward();
    } else {
      final double startOffset = _dragOffset;
      _animation = Tween<double>(
        begin: startOffset,
        end: 0.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

      setState(() {
        _dragOffset = 0.0;
      });

      _controller.reset();
      await _controller.forward();
    }
  }

  Widget _buildAnimatedCard(Widget child) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double currentOffset =
            _animation.isAnimating ? _animation.value : _dragOffset;
        final double rotation = (currentOffset / -150.0) * 0.2;

        return Transform(
          transform:
              Matrix4.identity()
                ..translate(0.0, currentOffset)
                ..rotateZ(rotation),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: child,
    );
  }

  Widget _buildAnimatedWallet(String image) {
    return AnimatedBuilder(
      animation: Listenable.merge([_animation, _SlideController]),
      builder: (context, child) {
        final double currentOffset =
            _animation.isAnimating ? _animation.value : _dragOffset;
        final double ImageSize = (currentOffset / -150.0) * 0.2;
        return AnimatedBuilder(
          animation: _walletAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _walletAnimation.value * 600),
              child: child,
            );
          },
          child: Padding(
            padding: EdgeInsets.only(
              top: (ImageSize * 80),
              right: (ImageSize * 80),
              left: (ImageSize * 80),
            ),
            child: Align(alignment: Alignment.bottomCenter, child: child),
          ),
        );
      },
      child: Image.asset(image, fit: BoxFit.fill),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // wallet back
                Positioned(
                  top: -65,
                  left: -25,
                  right: -25,
                  child: IgnorePointer(
                    child: _buildAnimatedWallet('assets/walletBack.png'),
                  ),
                ),

                // First Card
                if (_showFirstCard)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    top: _hideBalance ? 10 : -15,
                    left: 5,
                    right: 5,
                    child: GestureDetector(
                      onVerticalDragUpdate: _onDragUpdate,
                      onVerticalDragEnd: _onDragEnd,
                      child: _buildAnimatedCard(
                        Hero(
                          tag: 'card_animation',
                          flightShuttleBuilder: (
                            BuildContext flightContext,
                            Animation<double> animation,
                            HeroFlightDirection flightDirection,
                            BuildContext fromHeroContext,
                            BuildContext toHeroContext,
                          ) {
                            return RotationTransition(
                              turns: animation.drive(
                                Tween<double>(
                                  begin: 0.0,
                                  end: 0.25,
                                ).chain(CurveTween(curve: Curves.easeInOut)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5.0,
                                ),
                                child: Image.asset(
                                  'assets/background-removed.png',
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5.0,
                            ),
                            child: Image.asset('assets/background-removed.png'),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Front wallet
                Positioned(
                  top: -20,
                  left: -15,
                  right: -15,
                  child: IgnorePointer(
                    child: _buildAnimatedWallet('assets/wallet.png'),
                  ),
                ),

                // Second Card
                if (!_showFirstCard)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    top: _showSecondCard ? 0 : -15,
                    left: _showSecondCard ? 0 : 5,
                    right: _showSecondCard ? 0 : 5,
                    child: GestureDetector(
                      onVerticalDragUpdate: _onDragUpdate,
                      onVerticalDragEnd: _onDragEnd,
                      child: _buildAnimatedCard(
                        Hero(
                          tag: 'card_animation',
                          flightShuttleBuilder: (
                            BuildContext flightContext,
                            Animation<double> animation,
                            HeroFlightDirection flightDirection,
                            BuildContext fromHeroContext,
                            BuildContext toHeroContext,
                          ) {
                            return RotationTransition(
                              turns: animation.drive(
                                Tween<double>(
                                  begin: 0.0,
                                  end: 0.25,
                                ).chain(CurveTween(curve: Curves.easeInOut)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5.0,
                                ),
                                child: Image.asset(
                                  'assets/background-removed.png',
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5.0,
                            ),
                            child: Image.asset('assets/background-removed.png'),
                          ),
                        ),
                      ),
                    ),
                  ),

                Positioned(
                  top: 310,
                  right: 20,
                  child: InkWell(
                    onTap: () {
                      _hideBalance = !_hideBalance;
                      setState(() {});
                    },
                    child: SizedBox(height: 50, width: 130),
                  ),
                ),
              ],
            ),
          ),

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
                    onPressed: () {
                      _SlideController.reverse();
                      Future.delayed(
                        const Duration(milliseconds: 300),
                        () async {
                          await Navigator.of(
                            context,
                          ).push(CustomPageRoute(child: const AtmMachine()));
                          _SlideController.forward();
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Withdraw',
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
}
