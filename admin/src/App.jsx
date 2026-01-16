import { useContext } from "react";
import { AppContext } from "./context/AppContextProvider";
import Login from "./pages/Login";
import Navbar from "./components/Navbar";
import Sidebar from "./components/Sidebar";
import { Navigate, Route, Routes } from "react-router";
import Dashboard from "./pages/Dashboard";
import SportsManagement from "./pages/SportsManagement";
import Box from "@mui/joy/Box";
import AdminAnalytics from "./pages/AdminAnalytics";

export default function App() {
    const { aToken } = useContext(AppContext);

    return (
        aToken ? (
            <Box
                sx={{
                    display: "flex",
                    flexDirection: "column",
                    height: "100vh",
                    width: "100vw",
                    overflow: "hidden",
                    backgroundColor: "#F8F9FD",
                }}
            >
                <Navbar />
                <Box
                    sx={{
                        display: "flex",
                        flex: 1,
                        width: "100%",
                        overflow: "hidden",
                    }}
                >
                    <Sidebar />
                    <Box
                        sx={{
                            flex: 1,
                            width: "100%",
                            overflowY: "auto",
                            overflowX: "hidden",
                        }}
                    >
                        <Routes>
                            <Route path="/" element={<Navigate to="/admin-dashboard" />} />
                            <Route path="/admin-dashboard" element={<Dashboard />} />
                            <Route path="/sports-management" element={<SportsManagement />} />
                            <Route path="/admin/analytics" element={<AdminAnalytics />} />
                        </Routes>
                    </Box>
                </Box>
            </Box>
        ) : (
            <Login />
        )
    );
}