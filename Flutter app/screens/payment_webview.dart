// payment_webview.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:url_launcher/url_launcher.dart';


import 'student/student_dashboard.dart';

class PaymentWebView extends StatefulWidget {
  final String url;
  final String? bookingId;
  final bool isExtension;
  final bool isCompletePayment;

  const PaymentWebView({
    super.key,
    required this.url,
    this.bookingId,
    this.isExtension = false,
    this.isCompletePayment = false,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  WebViewController? _controller;
  bool _loadingPage = true;
  bool _hasError = false;
  bool _controllerInitialized = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      
      // Correct way to create WebViewController in webview_flutter 4.4+
      late final PlatformWebViewControllerCreationParams params;
      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      final WebViewController controller =
          WebViewController.fromPlatformCreationParams(params);

      // Enable JavaScript (required for most payment gateways)
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);

      // Android-specific improvements
      if (controller.platform is AndroidWebViewController) {
        AndroidWebViewController.enableDebugging(false);
        (controller.platform as AndroidWebViewController)
            .setMediaPlaybackRequiresUserGesture(false);
      }

      // Navigation delegate
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _loadingPage = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _loadingPage = false);
            }
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _loadingPage = false;
                _hasError = true;
                _errorMessage = error.description.isNotEmpty
                    ? error.description
                    : 'Connection failed. Try opening in browser.';
              });
            }
          },
          onNavigationRequest: (request) {
            final url = request.url;
           
            // Success callback detection (adjust based on your backend)
            if (url.contains('/callback') ||
                url.contains('success') ||
                url.contains('payment/success') ||
                url.contains('verify')) {

              final uri = Uri.parse(url);
              final transactionId = uri.queryParameters['transaction_id'] ??
                  uri.queryParameters['tx_ref'] ??
                  uri.queryParameters['reference'] ??
                  uri.queryParameters['trxref'];

            
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.isExtension 
                          ? 'Extension Payment Successful! Your booking is being updated.'
                          : widget.isCompletePayment
                              ? 'Complete Payment Successful! Your booking is being updated.'
                              : 'Payment Successful! Your booking is being processed.'
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
                
                // Navigate back to student dashboard with proper refresh
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDashboard(
                      initialIndex: 1, // Bookings tab
                      transactionReference: transactionId,
                      paymentArguments: {
                        'isExtension': widget.isExtension,
                        'isCompletePayment': widget.isCompletePayment,
                      },
                    ),
                  ),
                  (route) => false,
                );
              }

              return NavigationDecision.prevent;
            }

            // Cancel / Failure
            if (url.contains('cancel') || url.contains('failed') || url.contains('declined')) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment was cancelled or failed'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pop(context);
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

      // Load the payment URL
      await controller.loadRequest(Uri.parse(widget.url));

      if (mounted) {
        setState(() {
          _controller = controller;
          _controllerInitialized = true;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingPage = false;
          _hasError = true;
          _errorMessage = 'Failed to load payment page';
        });
      }
    }
  }




  Future<void> _launchInBrowser() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open browser")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Payment",
        style: TextStyle(
          color: Colors.white,
        )
        ),
        backgroundColor: const Color(0xFF07746B),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser,
            color: Color(0xFFFFFFFF),
            ),
            tooltip: "Open in Browser",
            onPressed: _launchInBrowser,
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView
          if (_controllerInitialized && _controller != null)
            WebViewWidget(controller: _controller!)
          else if (_hasError)
            // Error UI
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 80, color: Colors.red),
                    const SizedBox(height: 24),
                    const Text(
                      'Unable to load payment page',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _hasError = false;
                              _loadingPage = true;
                              _controllerInitialized = false;
                            });
                            _initializeWebView();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text("Retry"),
                        ),
                        ElevatedButton.icon(
                          onPressed: _launchInBrowser,
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text("Open in Browser"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            // Initial loading
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text("Loading secure payment page...", style: TextStyle(fontSize: 16)),
                ],
              ),
            ),

          // Loading overlay
          if (_loadingPage)
            const Opacity(
              opacity: 0.8,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clean up if needed
    super.dispose();
  }
}
