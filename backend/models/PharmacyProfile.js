const mongoose = require("mongoose");

const pharmacyProfileSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    name: { type: String, required: true },
    location: { type: String, required: true },
    panNumber: { type: String, required: true },
    phoneNumber: { type: String, required: true },
    subscription: {
      plan: {
        type: String,
        enum: ["1 month", "3 months", "6 months", "none"],
        default: "none",
      },
      startDate: { type: Date },
      expiryDate: { type: Date },
      isActive: { type: Boolean, default: false },
      paymentReference: { type: String },
      paymentProofImage: { type: String }, // URL or Base64 of the payment statement image
    },
    problemReport: {
      description: { type: String }, // User's problem description
      reportedAt: { type: Date },
      status: { type: String, enum: ["pending", "resolved"], default: "pending" }
    },
  },
  { timestamps: true },
);

module.exports = mongoose.model("PharmacyProfile", pharmacyProfileSchema);
