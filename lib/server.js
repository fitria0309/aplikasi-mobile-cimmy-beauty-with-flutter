const express = require('express');
const stripe = require('stripe')('sk_test_51J4TSZLqzEftk...');  // Ganti dengan Secret Key Anda
const app = express();
app.use(express.json());

app.post('/create-payment-intent', async (req, res) => {
  const { amount } = req.body; // jumlah pembayaran dalam sen (misal $10 = 1000)

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: 'usd',
    });

    res.send({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (e) {
    res.status(400).send({
      error: e.message,
    });
  }
});

app.listen(4242, () => {
  console.log('Server is running on port 4242');
});
