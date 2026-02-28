const express = require("express");
const router = express.Router();
const ReturnItem = require("../models/Return");

// Get all returns
router.get("/", async (req, res) => {
  try {
    const returns = await ReturnItem.find();
    res.json(returns);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Create return
router.post("/", async (req, res) => {
  const returnItem = new ReturnItem(req.body);
  try {
    const newReturn = await returnItem.save();
    res.status(201).json(newReturn);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Update return status
router.put("/:id", async (req, res) => {
  try {
    const updatedReturn = await ReturnItem.findByIdAndUpdate(
      req.params.id,
      req.body,
      { returnDocument: "after" },
    );
    res.json(updatedReturn);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Delete return
router.delete("/:id", async (req, res) => {
  try {
    await ReturnItem.findByIdAndDelete(req.params.id);
    res.json({ message: "Return deleted" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
