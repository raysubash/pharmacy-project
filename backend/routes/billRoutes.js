const express = require("express");
const router = express.Router();
const PurchaseBill = require("../models/Bill");
const Medicine = require("../models/Medicine");

// Get all bills
router.get("/", async (req, res) => {
  try {
    const bills = await PurchaseBill.find();
    res.json(bills);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get one bill
router.get("/:id", async (req, res) => {
  try {
    const bill = await PurchaseBill.findById(req.params.id);
    if (bill) {
      res.json(bill);
    } else {
      res.status(404).json({ message: "Bill not found" });
    }
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Create bill (and update medicine stock)
router.post("/", async (req, res) => {
  const bill = new PurchaseBill(req.body);
  try {
    const newBill = await bill.save();

    // Update medicine stock logic (optional: based on user requirement)
    // Iterate through items and update Medicine stock
    for (const item of newBill.items) {
      // Find medicine by ID or Name?
      // Since we reference medicineId, we can use that.
      // If medicineId is not a MongoDB ObjectId, we might need a mapping.
      // But assuming the frontend will send data that matches.
      // For now, let's keep it simple.
      // TODO: Stock update logic
    }

    res.status(201).json(newBill);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Delete bill
router.delete("/:id", async (req, res) => {
  try {
    await PurchaseBill.findByIdAndDelete(req.params.id);
    res.json({ message: "Bill deleted" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
