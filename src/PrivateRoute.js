import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuthState } from 'react-firebase-hooks/auth';
import { auth } from './firebase';

function PrivateRoute({ element }) {
  const [user] = useAuthState(auth);

  return user ? element : <Navigate to="/signin" />;
}

export default PrivateRoute;

