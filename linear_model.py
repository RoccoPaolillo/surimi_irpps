import numpy as np
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression
import pandas as pd
import os
import openpyxl

# Generate synthetic data (continuous predictor → continuous output)
os.chdir("C:/Users/rocpa/OneDrive/Documenti/GitHub/surimi_upload/")


df = pd.read_excel("grid_df.xlsx", engine="openpyxl")

X = df.depth
y = 2 * X + np.sin(2 * X) + np.random.normal(0, 0.2, X.shape)  # True function with noise

# Create and fit the Linear Regression model
np.random.seed(42)
model = LinearRegression()
model.fit(X, y)

# Make predictions
y_pred = model.predict(X)

# Print model coefficients
print(f"Intercept: {model.intercept_[0]:.4f}")
print(f"Coefficient: {model.coef_[0][0]:.4f}")

# Plot the results
plt.scatter(X, y, label="True Data")
plt.plot(X, y_pred, color="red", label="Linear Regression Prediction")
plt.xlabel("Input Feature (X)")
plt.ylabel("Output (y)")
plt.legend()
plt.title("Linear Regression with sklearn")
plt.show()