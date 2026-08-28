const express = require("express");
const router = express.Router();
const Medicine = require("../models/Medicine");
const { recordStockMovement } = require("../services/stockService");

// Get all medicines
router.get("/", async (req, res) => {
  try {
    const medicines = await Medicine.find();
    res.json(medicines);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Lookup medicine by barcode (must be BEFORE /:id to avoid route conflict)
router.get("/barcode/:code", async (req, res) => {
  try {
    const medicine = await Medicine.findOne({ barcode: req.params.code });
    if (medicine) {
      res.json(medicine);
    } else {
      res.status(404).json({ message: "No medicine found for this barcode" });
    }
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get one medicine
router.get("/:id", async (req, res) => {
  try {
    const medicine = await Medicine.findById(req.params.id);
    if (medicine) {
      res.json(medicine);
    } else {
      res.status(404).json({ message: "Medicine not found" });
    }
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Create medicine — if initialStock > 0, create an INITIAL transaction
router.post("/", async (req, res) => {
  const initialStock = req.body.currentStock || 0;
  // Set currentStock to 0; it will be set via INITIAL transaction if needed
  const medicineData = { ...req.body, currentStock: 0 };
  const medicine = new Medicine(medicineData);

  try {
    const newMedicine = await medicine.save();

    // If initial stock was specified, record it as an INITIAL transaction
    if (initialStock > 0) {
      try {
        await recordStockMovement({
          medicineId: newMedicine._id.toString(),
          type: "INITIAL",
          quantity: initialStock,
          reason: "Initial stock on medicine creation",
          userId: "system",
        });
        // Re-fetch to get updated currentStock
        const updated = await Medicine.findById(newMedicine._id);
        return res.status(201).json(updated);
      } catch (stockErr) {
        // Medicine was created but stock transaction failed — return with warning
        return res.status(201).json({
          ...newMedicine.toObject(),
          warning: `Medicine created but initial stock failed: ${stockErr.message}`,
        });
      }
    }

    res.status(201).json(newMedicine);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Update medicine — currentStock is STRIPPED from body to prevent direct editing
router.put("/:id", async (req, res) => {
  try {
    // Remove currentStock from update payload — stock changes only via stockService
    const { currentStock, ...safeBody } = req.body;

    const updatedMedicine = await Medicine.findByIdAndUpdate(
      req.params.id,
      safeBody,
      { returnDocument: "after" },
    );
    res.json(updatedMedicine);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Delete medicine
router.delete("/:id", async (req, res) => {
  try {
    await Medicine.findByIdAndDelete(req.params.id);
    res.json({ message: "Medicine deleted" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
