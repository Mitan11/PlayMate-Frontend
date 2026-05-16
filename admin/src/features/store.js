import { configureStore } from "@reduxjs/toolkit";
import authReducer from "./auth/authSlice";
import sportsReducer from "./sports/sportsSlice";
import usersReducer from "./users/usersSlice";
import venuesReducer from "./venues/venuesSlice";
import postsReducer from "./posts/postsSlice";
import dashboardReducer from "./dashboard/dashboardSlice";
import analyticsReducer from "./analytics/analyticsSlice";

export const store = configureStore({
    reducer: {
        auth: authReducer,
        sports: sportsReducer,
        users: usersReducer,
        venues: venuesReducer,
        posts: postsReducer,
        dashboard: dashboardReducer,
        analytics: analyticsReducer,
    },
});