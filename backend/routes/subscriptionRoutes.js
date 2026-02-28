const express = require("express");
const router = express.Router();
const PharmacyProfile = require("../models/PharmacyProfile");
const axios = require("axios");

// Manual Statement Upload
router.post("/upload-statement", async (req, res) => {
  try {
    const { pharmacyId, plan, amount, paymentProofImage } = req.body;

    // Validate inputs
    if (!pharmacyId || !plan || !amount) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    // In a real app, you would verify the image or upload it to S3/Cloudinary here.
    // For this prototype, we'll store the Base64 string directly in the database (not recommended for large scale).

    // Calculate expiry
    let durationInMonths = 0;
    if (plan.includes("1")) durationInMonths = 1;
    else if (plan.includes("3")) durationInMonths = 3;
    else if (plan.includes("6")) durationInMonths = 6;

    const startDate = new Date();
    const expiryDate = new Date();
    expiryDate.setMonth(startDate.getMonth() + durationInMonths);

    // Update Profile
    const updatedProfile = await PharmacyProfile.findByIdAndUpdate(
      pharmacyId,
      {
        $set: {
          "subscription.plan": plan,
          "subscription.startDate": startDate,
          "subscription.expiryDate": expiryDate,
          "subscription.isActive": true, // Ideally set to false until admin verifies
          "subscription.paymentReference": "MANUAL_UPLOAD",
          "subscription.paymentProofImage": paymentProofImage,
        },
      },
      { returnDocument: "after" },
    );

    if (!updatedProfile) {
      return res.status(404).json({ error: "Pharmacy Profile not found" });
    }

    res.json({
      message: "Statement uploaded and subscription pending verification",
      subscription: updatedProfile.subscription,
    });
  } catch (err) {
    console.error("Statement Upload Error:", err);
    res.status(500).json({ error: "Server Error" });
  }
});

// Initiate Khalti Payment
router.post("/initiate-khalti", async (req, res) => {
  try {
    const {
      amount,
      purchase_order_id,
      purchase_order_name,
      return_url,
      website_url,
      customer_info,
    } = req.body;

    // Amount from frontend is in Rupees, convert to Paisa for Khalti
    // Ensure amount is an integer
    const amountInt = parseInt(amount);
    if (isNaN(amountInt)) {
      return res.status(400).json({ message: "Invalid amount" });
    }
    const amountInPaisa = amountInt * 100;

    const payload = {
      return_url: return_url || "https://khalti.com/payment_callback",
      website_url: website_url || "https://khalti.com/",
      amount: amountInPaisa,
      purchase_order_id: purchase_order_id || `Order-${Date.now()}`,
      purchase_order_name: purchase_order_name || "Subscription Payment",
      customer_info: customer_info || {
        name: "Test User",
        email: "test@khalti.com",
        phone: "9800000000",
      },
    };

    console.log("Creating Khalti Payment with payload:", payload);

    const response = await axios.post(KHALTI_API_URL, payload, {
      headers: {
        Authorization: `Key ${KHALTI_SECRET_KEY}`,
        "Content-Type": "application/json",
      },
    });

    console.log("Khalti Response:", response.data);
    res.status(200).json(response.data);
  } catch (error) {
    const errorDetail = error.response ? error.response.data : error.message;
    console.error("Khalti initiation error:", errorDetail);

    if (error.response && error.response.status === 401) {
      return res.status(500).json({
        message:
          "Invalid Khalti Secret Key. Please update backend/routes/subscriptionRoutes.js with a valid Test Secret Key.",
        detail: errorDetail,
      });
    }

    res.status(500).json({
      message: "Failed to initiate Khalti payment",
      detail: errorDetail,
    });
  }
});

// Update subscription (called after successful payment)
router.post("/update", async (req, res) => {
  try {
    const { pharmacyId, plan, amount, paymentReference } = req.body;

    // Validate plan
    const plans = {
      "1 Month": 30,
      "3 Months": 90,
      "6 Months": 180,
    };

    if (!plans[plan]) {
      return res.status(400).json({ message: "Invalid plan selected" });
    }

    const startDate = new Date();
    const expiryDate = new Date();
    expiryDate.setDate(startDate.getDate() + plans[plan]);

    const profile = await PharmacyProfile.findById(pharmacyId);
    if (!profile) {
      return res.status(404).json({ message: "Pharmacy profile not found" });
    }

    profile.subscription = {
      plan,
      startDate,
      expiryDate,
      isActive: true,
      paymentReference,
    };

    await profile.save();

    res.status(200).json({
      message: "Subscription updated successfully",
      subscription: profile.subscription,
    });
  } catch (error) {
    console.error("Subscription update error:", error);
    res
      .status(500)
      .json({ message: "Server error during subscription update" });
  }
});

// Check subscription status
router.get("/status/:pharmacyId", async (req, res) => {
  try {
    const profile = await PharmacyProfile.findById(req.params.pharmacyId);
    if (!profile) {
      return res.status(404).json({ message: "Pharmacy profile not found" });
    }

    const isExpired =
      profile.subscription.expiryDate &&
      new Date() > new Date(profile.subscription.expiryDate);

    if (isExpired && profile.subscription.isActive) {
      profile.subscription.isActive = false;
      await profile.save();
    }

    res.status(200).json({
      subscription: profile.subscription,
      isExpired,
    });
  } catch (error) {
    console.error("Subscription status error:", error);
    res
      .status(500)
      .json({ message: "Server error fetching subscription status" });
  }
});

module.exports = router;
