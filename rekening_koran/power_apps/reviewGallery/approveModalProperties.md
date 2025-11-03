# ═══════════════════════════════════════════════════════════════════════════════
# MODAL CONFIRMATION - Power Apps Setup Guide
# ═══════════════════════════════════════════════════════════════════════════════

## **📋 COMPONENTS NEEDED:**

### **1. Variable (App Level atau Screen Level):**
```
Name: varShowApproveModal
Type: Boolean
Default: false
```

### **2. Modal Container (Rectangle atau Blank Screen):**
```
Name: modalApproveConfirm
Visible: varShowApproveModal
Fill: RGBA(0, 0, 0, 0.6)  // Semi-transparent black overlay
Width: Parent.Width
Height: Parent.Height
X: 0
Y: 0
ZIndex: 1000
```

### **3. Modal Popup Card (Rectangle):**
```
Name: cardApproveModal
Visible: varShowApproveModal
Fill: White
Border: Solid, 2px, Black
BorderRadius: 8
Width: 500
Height: Auto (fit content)
X: (Parent.Width - Self.Width) / 2  // Center horizontally
Y: (Parent.Height - Self.Height) / 2  // Center vertically
ZIndex: 1001
```

### **4. Modal Title Label:**
```
Name: lblModalTitle
Text: "⚠️ KONFIRMASI APPROVAL"
Font: Bold, 18px
Color: Red
Padding: 20px (top, left)
```

### **5. Modal Message Label:**
```
Name: lblModalMessage
Text: 
"Apakah Anda yakin ingin approve semua transaksi dengan status FAIR/GOOD/EXCELLENT dan memindahkannya ke MP_REKENING_KORAN?

Tindakan ini akan:
• Memindahkan transaksi ke table final
• Update status IsApproved = true
• Mencatat ApprovedBy dan ApprovedAt"
Width: cardApproveModal.Width - 40
Padding: 0, 20px
AutoHeight: true
```

### **6. Button "Yes" (Confirm):**
```
Name: btnModalYes
Text: "Yes, Approve"
Fill: Green
Color: White
OnSelect: [PASTE approveModalYesBtn.c content]
X: 20
Y: lblModalMessage.Y + lblModalMessage.Height + 20
Width: 150
```

### **7. Button "No" (Cancel):**
```
Name: btnModalNo
Text: "No, Cancel"
Fill: Gray
Color: White
OnSelect: [PASTE approveModalNoBtn.c content]
X: btnModalYes.X + btnModalYes.Width + 10
Y: btnModalYes.Y
Width: 150
```

### **8. Close Button (X icon - Optional):**
```
Name: btnModalClose
Text: "✕"
Fill: Transparent
Color: Gray
OnSelect: [PASTE approveModalNoBtn.c content]
X: cardApproveModal.Width - 30
Y: 10
Width: 30
Height: 30
```

---

## **🎨 VISUAL HIERARCHY:**

```
Screen
└─ modalApproveConfirm (Overlay - semi-transparent)
   └─ cardApproveModal (White card, centered)
      ├─ btnModalClose (X button - top right)
      ├─ lblModalTitle (Title)
      ├─ lblModalMessage (Message text)
      ├─ btnModalYes (Green button)
      └─ btnModalNo (Gray button)
```

---

## **⚙️ PROPERTIES SETUP:**

### **modalApproveConfirm (Overlay):**
```
Visible = varShowApproveModal
OnSelect = Set(varShowApproveModal, false)  // Click outside to close
```

### **cardApproveModal (Card):**
```
Visible = varShowApproveModal
OnSelect = Reset(varShowApproveModal)  // Prevent close when clicking card
```

---

## **🔧 ALTERNATIVE: Pakai Power Apps Component (Recommended)**

Jika mau lebih simple, bisa pakai **Power Apps Component**:

1. Create Component: `ApproveConfirmationModal`
2. Input Property: `OnConfirm` (Action type)
3. Output Property: `IsVisible` (Boolean)
4. Inside component: Modal UI + Buttons
5. Use in Screen: 
   ```powerappsfx
   <Component>.OnConfirm = btnApproveAll_OnSelect
   <Component>.IsVisible = varShowApproveModal
   ```

---

## **📱 QUICK SETUP STEPS:**

1. **Create Variable:**
   - App Variables → New → `varShowApproveModal` (Boolean, default: false)

2. **Add Modal Overlay:**
   - Insert → Rectangle
   - Name: `modalApproveConfirm`
   - Visible: `varShowApproveModal`
   - Fill: `RGBA(0, 0, 0, 0.6)`
   - Width/Height: `Parent.Width/Height`

3. **Add Modal Card:**
   - Insert → Rectangle (inside overlay)
   - Name: `cardApproveModal`
   - Fill: White
   - Center on screen

4. **Add Labels & Buttons:**
   - Title, Message, Yes button, No button

5. **Wire Up Buttons:**
   - `btnApproveAll` OnSelect: `Set(varShowApproveModal, true)`
   - `btnModalYes` OnSelect: [Paste `approveModalYesBtn.c`]
   - `btnModalNo` OnSelect: [Paste `approveModalNoBtn.c`]

---

## **✅ TESTING:**

1. Click `btnApproveAll` → Modal should appear
2. Click "Yes" → Should execute approval + close modal
3. Click "No" → Should close modal without action
4. Click outside modal → Should close modal

---

**SETUP COMPLETE!** 🎉

