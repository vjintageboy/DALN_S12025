const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const axios = require('axios');

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

// MoMo Config
const config = {
    partnerCode: "MOMO",
    accessKey: "F8BBA842ECF85",
    secretKey: "K951B6PE1waDMi640xX08PD3vg6EkVlz",
    endpoint: "https://test-payment.momo.vn/v2/gateway/api/create"
};

app.post('/momo/create', async (req, res) => {
    try {
        const { amount } = req.body;

        if (!amount) {
            return res.status(400).json({ message: "Amount is required" });
        }

        const orderId = "MOMO" + new Date().getTime();
        const requestId = orderId;
        const orderInfo = "Thanh toan don hang " + orderId;
        const redirectUrl = "https://google.com";
        const ipnUrl = "https://google.com";
        const requestType = "captureWallet";
        const extraData = "";
        const amountStr = amount.toString();

        // Signature Generation
        const rawSignature =
            `accessKey=${config.accessKey}&amount=${amountStr}&extraData=${extraData}&ipnUrl=${ipnUrl}` +
            `&orderId=${orderId}&orderInfo=${orderInfo}&partnerCode=${config.partnerCode}` +
            `&redirectUrl=${redirectUrl}&requestId=${requestId}&requestType=${requestType}`;

        const signature = crypto
            .createHmac('sha256', config.secretKey)
            .update(rawSignature)
            .digest('hex');

        const requestBody = {
            partnerCode: config.partnerCode,
            partnerName: "Test",
            storeId: "MoMoTestStore",
            requestId: requestId,
            amount: amountStr,
            orderId: orderId,
            orderInfo: orderInfo,
            redirectUrl: redirectUrl,
            ipnUrl: ipnUrl,
            lang: "vi",
            extraData: extraData,
            requestType: requestType,
            signature: signature
        };

        console.log("Sending to MoMo:", requestBody);

        const response = await axios.post(config.endpoint, requestBody);

        console.log("MoMo Response:", response.data);

        return res.status(200).json(response.data);

    } catch (error) {
        console.error("Error:", error.message);
        if (error.response) {
            console.error("MoMo Error Body:", error.response.data);
        }
        return res.status(500).json({
            message: "Internal Server Error",
            details: error.message
        });
    }
});

app.listen(port, () => {
    console.log(`Backend running at http://localhost:${port}`);
});
