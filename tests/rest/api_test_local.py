import http.client
import unittest
import json
import pytest

from app.api import api_application


@pytest.mark.api
class TestApiLocal(unittest.TestCase):
    def setUp(self):
        """Set up test client for Flask application"""
        self.app = api_application
        self.client = self.app.test_client()

    def test_api_add(self):
        """Test successful addition"""
        response = self.client.get("/calc/add/2/2")
        self.assertEqual(response.status_code, http.client.OK)
        self.assertEqual(response.data.decode(), "4")

    def test_api_add_invalid_parameter(self):
        """Test add with invalid parameter"""
        response = self.client.get("/calc/add/abc/2")
        self.assertEqual(response.status_code, http.client.BAD_REQUEST)

    def test_api_substract(self):
        """Test successful subtraction"""
        response = self.client.get("/calc/substract/5/3")
        self.assertEqual(response.status_code, http.client.OK)
        self.assertEqual(response.data.decode(), "2")

    def test_api_substract_invalid_parameter(self):
        """Test substract with invalid parameter"""
        response = self.client.get("/calc/substract/abc/2")
        self.assertEqual(response.status_code, http.client.BAD_REQUEST)

    def test_api_multiply(self):
        """Test successful multiplication"""
        response = self.client.get("/calc/multiply/2/3")
        self.assertEqual(response.status_code, http.client.OK)
        self.assertEqual(response.data.decode(), "6")

    def test_api_multiply_invalid_parameter(self):
        """Test multiply with invalid parameter"""
        response = self.client.get("/calc/multiply/abc/2")
        self.assertEqual(response.status_code, http.client.BAD_REQUEST)

    def test_api_divide(self):
        """Test successful division"""
        response = self.client.get("/calc/divide/6/2")
        self.assertEqual(response.status_code, http.client.OK)
        self.assertEqual(response.data.decode(), "3.0")

    def test_api_divide_by_zero(self):
        """Test division by zero error"""
        response = self.client.get("/calc/divide/1/0")
        self.assertEqual(response.status_code, http.client.BAD_REQUEST)

    def test_api_divide_invalid_parameter(self):
        """Test divide with invalid parameter"""
        response = self.client.get("/calc/divide/abc/2")
        self.assertEqual(response.status_code, http.client.BAD_REQUEST)

    def test_api_power(self):
        """Test successful power operation"""
        response = self.client.get("/calc/power/2/3")
        self.assertEqual(response.status_code, http.client.OK)
        self.assertEqual(response.data.decode(), "8")

    def test_api_power_invalid_parameter(self):
        """Test power with invalid parameter"""
        response = self.client.get("/calc/power/abc/2")
        self.assertEqual(response.status_code, http.client.BAD_REQUEST)

    def test_api_sqrt(self):
        """Test successful square root"""
        response = self.client.get("/calc/sqrt/4")
        self.assertEqual(response.status_code, http.client.OK)
        self.assertEqual(response.data.decode(), "2.0")

    def test_api_sqrt_negative_number(self):
        """Test square root of negative number"""
        response = self.client.get("/calc/sqrt/-1")
        self.assertEqual(response.status_code, http.client.BAD_REQUEST)

    def test_api_sqrt_invalid_parameter(self):
        """Test sqrt with invalid parameter"""
        response = self.client.get("/calc/sqrt/abc")
        self.assertEqual(response.status_code, http.client.BAD_REQUEST)

    def test_api_log10(self):
        """Test successful log10 operation"""
        response = self.client.get("/calc/log10/10")
        self.assertEqual(response.status_code, http.client.OK)
        self.assertEqual(response.data.decode(), "1.0")

    def test_api_log10_zero(self):
        """Test log10 of zero"""
        response = self.client.get("/calc/log10/0")
        self.assertEqual(response.status_code, http.client.BAD_REQUEST)

    def test_api_log10_negative_number(self):
        """Test log10 of negative number"""
        response = self.client.get("/calc/log10/-1")
        self.assertEqual(response.status_code, http.client.BAD_REQUEST)

    def test_api_log10_invalid_parameter(self):
        """Test log10 with invalid parameter"""
        response = self.client.get("/calc/log10/abc")
        self.assertEqual(response.status_code, http.client.BAD_REQUEST)

    def test_api_hello(self):
        """Test hello endpoint"""
        response = self.client.get("/")
        self.assertEqual(response.status_code, http.client.OK)


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
