import axios from "axios";

const API_URL = import.meta.env.VITE_BACKEND_URL || "http://localhost:4000/api/v1";

const getAuthHeaders = (token) => ({
    Authorization: `Bearer ${token}`,
});

export const venuesApi = {
    fetchVenues: async (token) => {
        const response = await axios.get(`${API_URL}/admin/getVenues`, {
            headers: getAuthHeaders(token),
        });
        return response.data;
    },
    deleteVenue: async (token, venueId) => {
        const response = await axios.delete(`${API_URL}/admin/deleteVenue/${venueId}`, {
            headers: getAuthHeaders(token),
        });
        return response.data;
    },
};
