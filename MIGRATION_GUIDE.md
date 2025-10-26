# Migration Guide: Employee Registration & Approval System

## 🔄 **What Changed**

Your app now uses a **new employee registration and approval workflow** with Employee IDs (Eid) instead of direct user registration.

## 📋 **New Workflow**

### **Before (Old System):**
1. User registers → Direct access to app
2. Admin manually verifies later
3. Uses Firebase UID for everything

### **After (New System):**
1. **Employee registers** → Status: `pending`
2. **Admin reviews and approves** → Assigns Employee ID (Eid)
3. **Employee can login** → Uses Eid for all operations
4. **All data organized by Eid** (attendance, location, salary)

## 🔧 **Files Created**

1. **`updated_login_service.dart`** - New authentication service
2. **`updated_loginpage.dart`** - New login UI with proper error handling
3. **`updated_firestore_security_rules.txt`** - Security rules for new system
4. **`employee_workflow_example.dart`** - Service classes for all operations
5. **`admin_panel_example.dart`** - Admin interface for approvals

## ⚡ **What You Need to Do**

### **Step 1: Update Firestore Security Rules**
```bash
# Copy the rules from updated_firestore_security_rules.txt
# Paste them in Firebase Console > Firestore Database > Rules
```

### **Step 2: Create Initial Admin**
```javascript
// In Firebase Console > Firestore Database
// Create collection: admins
// Document ID: {your-firebase-uid}
// Data: { "role": "admin" }
```

### **Step 3: Replace Login Page**
```dart
// In your main.dart, replace:
import 'loginpage.dart';
// With:
import 'updated_loginpage.dart';

// And replace LoginPage() with UpdatedLoginPage()
```

### **Step 4: Update Registration**
Your current `signup_page.dart` needs to be updated to use the new employee registration system. The new system:
- Creates record in `/employees/{firebaseUid}` with `status: 'pending'`
- Waits for admin approval
- Admin assigns Eid and creates user profile

### **Step 5: Update All Services**
Replace your current services with the new ones that use Eid:
- **Attendance**: Use `AttendanceService` from `employee_workflow_example.dart`
- **Location**: Use `LocationService` from `employee_workflow_example.dart`
- **Salary**: Use `SalaryService` from `employee_workflow_example.dart`

## 🔑 **Key Changes in Code**

### **Login Process:**
```dart
// OLD: Direct Firestore query
FirebaseFirestore.instance.collection("users").where("email", isEqualTo: email)

// NEW: Firebase Auth + Employee status check
final result = await UpdatedLoginService.loginEmployee(
  emailOrPhone: email,
  password: password,
);
```

### **Data Storage:**
```dart
// OLD: Using Firebase UID
collection("attendance").doc(firebaseUid)

// NEW: Using Employee ID (Eid)
collection("attendance").doc(eid)
```

### **Session Management:**
```dart
// OLD: Stores Firebase UID
SessionManager.saveUserSession(customUid: firebaseUid, ...)

// NEW: Stores Employee ID (Eid)
SessionManager.saveUserSession(customUid: eid, ...)
```

## 🚀 **Testing the New System**

### **1. Test Employee Registration:**
- Register a new employee
- Check `/employees` collection for pending status
- Verify email verification is sent

### **2. Test Admin Approval:**
- Login as admin
- Use admin panel to approve employee
- Verify Eid is assigned and user profile created

### **3. Test Employee Login:**
- Try login before approval (should show pending message)
- Try login after approval (should work with Eid)

## 📊 **Data Structure Examples**

### **Employee Record (`/employees/{firebaseUid}`):**
```json
{
  "firebaseUid": "abc123",
  "email": "employee@company.com",
  "name": "John Doe",
  "status": "approved",
  "eid": "EMP001",
  "createdAt": "timestamp",
  "approvedAt": "timestamp"
}
```

### **User Profile (`/users/{eid}`):**
```json
{
  "eid": "EMP001",
  "firebaseUid": "abc123",
  "email": "employee@company.com",
  "name": "John Doe",
  "status": true
}
```

### **Attendance (`/attendance/{eid}/dates/{date}`):**
```json
{
  "eid": "EMP001",
  "date": "2025-10-20",
  "checkIn": "timestamp",
  "checkOut": "timestamp",
  "location": "geopoint"
}
```

## ⚠️ **Important Notes**

1. **Existing Users**: You'll need to migrate existing user data to the new structure
2. **Mobile Login**: Currently only email login is supported in the new system
3. **Admin Setup**: Make sure to create at least one admin before testing
4. **Security Rules**: The new rules are strict - only approved employees can access data
5. **Employee IDs**: Are generated sequentially (EMP001, EMP002, etc.)

## 🔍 **Troubleshooting**

### **"Permission Denied" Errors:**
- Check if Firestore security rules are updated
- Verify user has approved status and Eid
- Ensure admin record exists for admin operations

### **"Employee record not found":**
- User needs to register first
- Check `/employees` collection exists

### **"Pending approval" message:**
- Admin needs to approve the employee
- Use admin panel to assign Eid

## 📞 **Next Steps**

1. **Deploy the security rules** to Firebase Console
2. **Create initial admin** in Firestore
3. **Test the complete workflow** with a new employee registration
4. **Migrate existing users** to the new system (if needed)
5. **Update all existing services** to use Eid instead of Firebase UID

The new system provides better security, organized data structure, and proper admin control over employee access.
