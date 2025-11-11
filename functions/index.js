// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const cors = require('cors')({origin: true});

admin.initializeApp();
const db = admin.firestore();

// Paymob Configuration - Use optional chaining to prevent undefined errors
const getPaymobConfig = () => {
    const config = functions.config().paymob || {};
    return {
        apiKey: config.api_key || '',
        secretKey: config.secret_key || '',
        publicKey: config.public_key || '',
        hmacSecret: config.hmac_secret || '',
        iframeId: config.iframe_id || '',
        integrationId: config.integration_id || ''
    };
};

const PAYMOB_BASE_URL = 'https://accept.paymob.com/api';

// ==================== GET AUTH TOKEN ====================
async function getPaymobAuthToken() {
    try {
        const config = getPaymobConfig();

        if (!config.apiKey) {
            throw new Error('Paymob API key not configured');
        }

        const response = await axios.post(`${PAYMOB_BASE_URL}/auth/tokens`, {
            api_key: config.apiKey
        });

        return response.data.token;
    } catch (error) {
        console.error('Paymob auth error:', error.response?.data || error.message);
        throw new Error('Failed to authenticate with Paymob');
    }
}

// ==================== CREATE PAYMENT ORDER ====================
exports.createPaymobOrder = functions.https.onCall(async (data, context) => {
    // Authentication check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated'
        );
    }

    const { amount, currency = 'EGP', bookingId } = data;

    // Validation
    if (!amount || amount <= 0) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Valid amount is required'
        );
    }

    try {
        const config = getPaymobConfig();
        console.log(`Creating order for user ${context.auth.uid}, amount: ${amount}`);

        // Step 1: Get auth token
        const authToken = await getPaymobAuthToken();

        // Step 2: Create order
        const orderResponse = await axios.post(
            `${PAYMOB_BASE_URL}/ecommerce/orders`,
            {
                auth_token: authToken,
                delivery_needed: false,
                amount_cents: Math.round(amount * 100),
                currency: currency,
                items: []
            }
        );

        const orderId = orderResponse.data.id;
        console.log(`Order created: ${orderId}`);

        // Step 3: Get user data
        const userDoc = await db.collection('users').doc(context.auth.uid).get();
        const userData = userDoc.exists ? userDoc.data() : {};

        // Step 4: Create payment key
        const integrationId = parseInt(config.integrationId || '0');

        const paymentKeyResponse = await axios.post(
            `${PAYMOB_BASE_URL}/acceptance/payment_keys`,
            {
                auth_token: authToken,
                amount_cents: Math.round(amount * 100),
                expiration: 3600,
                order_id: orderId,
                billing_data: {
                    apartment: 'NA',
                    email: userData.email || 'user@smartcitytransport.com',
                    floor: 'NA',
                    first_name: userData.name?.split(' ')[0] || 'User',
                    street: 'NA',
                    building: 'NA',
                    phone_number: userData.phone || '+201000000000',
                    shipping_method: 'NA',
                    postal_code: 'NA',
                    city: 'Cairo',
                    country: 'EG',
                    last_name: userData.name?.split(' ').slice(1).join(' ') || 'Name',
                    state: 'Cairo'
                },
                currency: currency,
                integration_id: integrationId
            }
        );

        const paymentToken = paymentKeyResponse.data.token;
        console.log(`Payment key created`);

        // Save payment record
        await db.collection('payments').add({
            userId: context.auth.uid,
            bookingId: bookingId || null,
            orderId: orderId,
            amount: amount,
            currency: currency,
            paymentToken: paymentToken,
            status: 'pending',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        return {
            success: true,
            orderId: orderId,
            paymentToken: paymentToken,
            iframeUrl: `https://accept.paymob.com/api/acceptance/iframes/${config.iframeId}?payment_token=${paymentToken}`
        };
    } catch (error) {
        console.error('Error creating order:', error.response?.data || error.message);
        throw new functions.https.HttpsError(
            'internal',
            'Failed to create payment order: ' + (error.message || 'Unknown error')
        );
    }
});

// ==================== GET PAYMENT STATUS ====================
exports.getPaymentStatus = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }

    const { orderId } = data;

    try {
        const paymentsSnapshot = await db
            .collection('payments')
            .where('orderId', '==', orderId)
            .where('userId', '==', context.auth.uid)
            .limit(1)
            .get();

        if (paymentsSnapshot.empty) {
            throw new functions.https.HttpsError('not-found', 'Payment not found');
        }

        const payment = paymentsSnapshot.docs[0].data();
        return {
            status: payment.status,
            amount: payment.amount,
            currency: payment.currency,
            transactionId: payment.transactionId || null
        };
    } catch (error) {
        console.error('Error getting payment status:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});

// ==================== PAYMOB WEBHOOK ====================
exports.paymobWebhook = functions.https.onRequest(async (req, res) => {
    return cors(req, res, async () => {
        try {
            const data = req.body;
            console.log('Webhook received for order:', data.order);

            const config = getPaymobConfig();

            // Verify HMAC if secret is configured
            if (config.hmacSecret) {
                const crypto = require('crypto');
                const receivedHmac = req.query.hmac;

                const hmacString = [
                    data.amount_cents,
                    data.created_at,
                    data.currency,
                    data.error_occured,
                    data.has_parent_transaction,
                    data.id,
                    data.integration_id,
                    data.is_3d_secure,
                    data.is_auth,
                    data.is_capture,
                    data.is_refunded,
                    data.is_standalone_payment,
                    data.is_voided,
                    data.order,
                    data.owner,
                    data.pending,
                    data.source_data_pan,
                    data.source_data_sub_type,
                    data.source_data_type,
                    data.success
                ].join('');

                const calculatedHmac = crypto
                    .createHmac('sha512', config.hmacSecret)
                    .update(hmacString)
                    .digest('hex');

                if (calculatedHmac !== receivedHmac) {
                    console.error('Invalid HMAC signature');
                    return res.status(400).send('Invalid signature');
                }
            }

            const orderId = data.order;
            const transactionId = data.id;
            const success = data.success === 'true' || data.success === true;

            // Find payment record
            const paymentsSnapshot = await db
                .collection('payments')
                .where('orderId', '==', orderId)
                .limit(1)
                .get();

            if (!paymentsSnapshot.empty) {
                const paymentDoc = paymentsSnapshot.docs[0];
                const paymentData = paymentDoc.data();

                // Update payment status
                await paymentDoc.ref.update({
                    status: success ? 'succeeded' : 'failed',
                    transactionId: transactionId,
                    webhookData: data,
                    completedAt: admin.firestore.FieldValue.serverTimestamp()
                });

                // Update booking if exists
                if (paymentData.bookingId) {
                    await db.collection('bookings').doc(paymentData.bookingId).update({
                        paymentStatus: success ? 'completed' : 'failed',
                        status: success ? 'confirmed' : 'cancelled'
                    });

                    // Update user stats if successful
                    if (success) {
                        await db.collection('users').doc(paymentData.userId).update({
                            totalSpent: admin.firestore.FieldValue.increment(paymentData.amount),
                            totalRides: admin.firestore.FieldValue.increment(1)
                        });
                    }
                }

                console.log(`Payment ${success ? 'succeeded' : 'failed'} for order ${orderId}`);
            }

            res.json({ received: true });
        } catch (error) {
            console.error('Webhook error:', error);
            res.status(500).send('Webhook processing failed');
        }
    });
});