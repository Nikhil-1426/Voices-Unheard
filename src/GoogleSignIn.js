import React from 'react';
import { signInWithGoogle,db } from './firebase';
import { doc, setDoc } from "firebase/firestore";

function GoogleSignIn() {
  const handleGoogleSignIn = async () => {
    try {
      const result = await signInWithGoogle();
      const user = result.user;

      // Create user profile in Firestore
      const userRef = doc(db, 'users', user.uid);
      await setDoc(userRef, {
        uid: user.uid,
        displayName: user.displayName,
        email: user.email,
        photoURL: user.photoURL
      }, { merge: true });
      // You can add any post sign-in actions here, e.g., redirecting the user
    } catch (error) {
      console.error("Error signing in with Google: ", error);
    }
  };

  return (
    <div>
      <h2>Sign In with Google</h2>
      <button onClick={handleGoogleSignIn}>Sign In with Google</button>
    </div>
  );
}

export default GoogleSignIn;
