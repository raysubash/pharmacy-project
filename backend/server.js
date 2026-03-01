const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
require("dotenv").config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json({ limit: "50mb" }));
app.use(express.urlencoded({ limit: "50mb", extended: true }));

// MongoDB Connection
const MONGO_URI = process.env.MONGO_URI || "mongodb://localhost:27017/pharmacy";

const seedAdmin = require("./seedAdmin");

mongoose
  .connect(MONGO_URI)
  .then(() => {
    console.log("MongoDB connected");
    seedAdmin(); // Seed admin user on startup
  })
  .catch((err) => console.log(err));

// Routes
const medicineRoutes = require("./routes/medicineRoutes");
const billRoutes = require("./routes/billRoutes");
const returnRoutes = require("./routes/returnRoutes");
const profileRoutes = require("./routes/profileRoutes");
const saleRoutes = require("./routes/saleRoutes");
const authRoutes = require("./routes/authRoutes");
const adminRoutes = require("./routes/adminRoutes");

app.use("/api/medicines", medicineRoutes);
app.use("/api/bills", billRoutes);
app.use("/api/returns", returnRoutes);
app.use("/api/profile", profileRoutes);
app.use("/api/sales", saleRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/admin", adminRoutes);

const subscriptionRoutes = require("./routes/subscriptionRoutes");
app.use("/api/subscription", subscriptionRoutes);

app.get("/", (req, res) => {
  res.send("Pharmacy API is running");
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
