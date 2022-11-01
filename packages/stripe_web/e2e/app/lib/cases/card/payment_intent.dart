import 'dart:convert';

import 'package:app/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PayCardFieldPage extends StatefulWidget {
  const PayCardFieldPage({Key? key}) : super(key: key);

  @override
  State<PayCardFieldPage> createState() => _CardFieldPageState();
}

class _CardFieldPageState extends State<PayCardFieldPage> {
  late final CardEditController _controller = CardEditController();

  CardFieldInputDetails? _card;

  String? result;

  @override
  void initState() {
    _controller.addListener(update);
    _card = _controller.details;
    super.initState();
  }

  @override
  void dispose() {
    _controller.removeListener(update);
    _controller.dispose();
    super.dispose();
  }

  void update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            CardField(controller: _controller),
            Text(_controller.details.toJson().toString()),
            Text(result.toString()),
            TextButton(
              onPressed: () {
                _handlePayPress();
              },
              child: const Text('Pay'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayPress() async {
    if (_card?.complete == true) {
      return;
    }

    // 1. fetch Intent Client Secret from backend
    final serverResponse = await fetchPaymentIntentClientSecret();
    final clientSecret = serverResponse['clientSecret'];

    // 2. Gather customer billing information (ex. email)
    const billingDetails = BillingDetails(
      email: 'hi@example.com',
      phone: '+48888000888',
      address: Address(
        city: 'Houston',
        country: 'US',
        line1: '1459  Circle Drive',
        line2: '',
        state: 'Texas',
        postalCode: '77063',
      ),
    ); // mo mocked data for tests

    // 3. Confirm payment with card details
    // The rest will be done automatically using webhooks
    // ignore: unused_local_variable
    final paymentIntent = await Stripe.instance.confirmPayment(
      clientSecret,
      const PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(
          billingDetails: billingDetails,
        ),
      ),
    );

    setState(() {
      result = 'Payment State: ${paymentIntent.status.name}';
    });
  }

  Future<Map<String, dynamic>> fetchPaymentIntentClientSecret() async {
    final url = Uri.parse('$kApiUrl/create-payment-intent');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'currency': 'usd',
        'amount': 1099,
        'payment_method_types': ['card'],
        'request_three_d_secure': 'any',
      }),
    );
    return json.decode(response.body);
  }
}
