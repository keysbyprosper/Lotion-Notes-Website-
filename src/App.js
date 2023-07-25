import { BrowserRouter, Route, Routes } from "react-router-dom";
import "./index.css";
import Layout from "./Layout";
import WriteBox from "./WriteBox";
import Empty from "./Empty";
import Login from "./Login";
import React, { useState, useEffect } from 'react';


function App() {

    return (
        <BrowserRouter>
          <Routes>
            <Route element={<Layout />}>
              <Route path="/" element={<Empty />} />
              <Route path="/notes" element={<Empty />} />
              <Route
                path="/notes/:noteId/edit"
                element={<WriteBox edit={true} />}
              />
              <Route path="/notes/:noteId" element={<WriteBox edit={false} />} />
              {/* any other path */}
              <Route path="*" element={<Empty />} />
            </Route>
            <Route path = "/login" element  = {<Login />}></Route>
          </Routes>
        </BrowserRouter>
        )
}   

export default App;