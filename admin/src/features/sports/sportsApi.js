import axios from "axios";

const API_URL = import.meta.env.VITE_BACKEND_URL || "http://localhost:4000/api/v1";

const getAuthHeaders = (token) => ({
	Authorization: `Bearer ${token}`,
});

export const sportsApi = {
	fetchSports: async (token) => {
		const response = await axios.get(`${API_URL}/admin/getAllSports`, {
			headers: getAuthHeaders(token),
		});
		return response.data;
	},
	addSport: async (token, sportName) => {
		const response = await axios.post(
			`${API_URL}/admin/addSport`,
			{ sport_name: sportName },
			{ headers: getAuthHeaders(token) }
		);
		return response.data;
	},
	updateSport: async (token, sportId, sportName) => {
		const response = await axios.patch(
			`${API_URL}/admin/updateSport/${sportId}`,
			{ sport_name: sportName },
			{ headers: getAuthHeaders(token) }
		);
		return response.data;
	},
	deleteSport: async (token, sportId) => {
		const response = await axios.delete(`${API_URL}/admin/deleteSport/${sportId}`, {
			headers: getAuthHeaders(token),
		});
		return response.data;
	},
};
