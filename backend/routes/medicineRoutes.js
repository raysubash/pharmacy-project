const express = require("express");
const router = express.Router();
const Medicine = require("../models/Medicine");

// Get all medicines
router.get("/", async (req, res) => {
  try {
    const medicines = await Medicine.find();
    res.json(medicines);
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

// Create medicine
router.post("/", async (req, res) => {
  const medicine = new Medicine(req.body);
  try {
    const newMedicine = await medicine.save();
    res.status(201).json(newMedicine);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Update medicine
router.put("/:id", async (req, res) => {
  try {
    const updatedMedicine = await Medicine.findByIdAndUpdate(
      req.params.id,
      req.body,
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
