/*Login.js*/

import React, { useState, useEffect } from 'react';
import { googleLogout, useGoogleLogin } from '@react-oauth/google';

function Login({email, setEmail, user, setUser, profile, setProfile}) {

    const login = useGoogleLogin({
        onSuccess: (codeResponse) => {setUser(codeResponse)
        localStorage.setItem("user", JSON.stringify(codeResponse))
        },
        onError: (error) => console.log('Login Failed:', error)
        
    });
   
    // log out function to log the user out of google and set the profile array to null
   

    return (
        <div>
            <br />
            <button id = "login-button" onClick={() => login()}>Sign in with Google 🚀 </button>
        
        </div>
    );
}
export default Login;