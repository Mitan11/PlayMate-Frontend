import { useContext } from "react";
import { AppContext } from "./context/AppContextProvider";
import Login from "./pages/Login";
import Navbar from "./components/Navbar";
import Sidebar from "./components/Sidebar";
import { Navigate, Route, Routes } from "react-router";
import Dashboard from "./pages/Dashboard";
import Box from "@mui/joy/Box";
import Profile from "./pages/Profile";
import VenueAnalytics from "./pages/VenueAnalytics";
import VenueSports from "./pages/VenueSports";
import BookingsManagement from "./pages/BookingsManagement";
import SlotsManagement from "./pages/SlotsManagement";

export default function App() {
    const { token } = useContext(AppContext);

    return (
        token ? (
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
                            <Route path="/" element={<Navigate to="/dashboard" />} />
                            <Route path="/dashboard" element={<Dashboard />} />
                            <Route path="/profile" element={<Profile />} />
                            <Route path="/analytics" element={<VenueAnalytics />} />
                            <Route path="/venue-sports" element={<VenueSports />} />
                            <Route path="/bookings" element={<BookingsManagement />} />
                            <Route path="/slots" element={<SlotsManagement />} />
                            <Route path="*" element={<Navigate to="/dashboard" />} />
                        </Routes>
                    </Box>
                </Box>
            </Box>
        ) : (
            <>
                <Login />
            </>
        )
    )
}