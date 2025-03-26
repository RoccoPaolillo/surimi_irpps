from sklearn.linear_model import LinearRegression
import numpy as np
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression
import pandas as pd
import os
import openpyxl

# Generate synthetic data (continuous predictor → continuous output)
os.chdir("C:/Users/rocpa/OneDrive/Documenti/GitHub/surimi_upload/")

df = pd.read_excel("grid_df.xlsx", engine="openpyxl")

df_nnls = df[['depth', 'effort','ARA']].dropna()

X = df_nnls[['depth','effort']].values  # Independent variables
y = df_nnls['ARA'].values  # Dependent variable

model = LinearRegression(positive=True)  # Ensures non-negative coefficients
model.fit(X, y)

y_pred = model.predict(X)

# Linear

# Plot the results
plt.scatter(X, y, label="True Data")
plt.plot(X, y_pred, color="red", label="Linear Regression Prediction")
plt.xlabel("Input Feature (X)")
plt.ylabel("Output (y)")
plt.legend()
plt.title("Linear Regression with sklearn")
plt.show()

coef_sklearn = model.coef_
intercept_sklearn = model.intercept_

# Display results
print("NNLS Model Coefficients (Sklearn):")
print(f"Depth coefficient: {coef_sklearn[0]:.8f}")
print(f"Effort coefficient: {coef_sklearn[1]:.8f}")
print(f"Intercept: {intercept_sklearn:.8f}")

new_X = np.array([[644, 30.925]])
y_pred_new_X = model.predict(new_X)
print(f"Predicted ARA for depth=644, effort=30.925: {y_pred[0]:.4f}")

# plot results
plt.scatter(X[1], y, label="True Data")
plt.plot(X, y_pred, color="red", label="Linear Regression Prediction")
plt.xlabel("Input Feature (X)")
plt.ylabel("Output (y)")
plt.legend()
plt.title("Linear Regression with sklearn")
plt.show()

# interaction

df_nnls["depth_effort_interaction"] = df_nnls["depth"] * df_nnls["effort"]

# Define new predictor matrix including the interaction term
X_interaction = df_nnls[['depth', 'effort', 'depth_effort_interaction']].values

# Train NNLS regression with the interaction term
model_interaction = LinearRegression(positive=True)
model_interaction.fit(X_interaction, y)

y_interaction_pred = model_interaction.predict(X_interaction)

# Extract coefficients
coef_interaction = model_interaction.coef_
intercept_interaction = model_interaction.intercept_

# Display results
print("NNLS Model Coefficients with Interaction Term:")
print(f"Depth coefficient: {coef_interaction[0]:.8f}")
print(f"Effort coefficient: {coef_interaction[1]:.8f}")
print(f"Interaction coefficient: {coef_interaction[2]:.8f}")
print(f"Intercept: {intercept_interaction:.8f}")

from mpl_toolkits.mplot3d import Axes3D

fig = plt.figure(figsize=(10, 7))
ax = fig.add_subplot(111, projection='3d')

# Scatter plot of actual depth, effort, and predicted ARA with interaction
ax.scatter(df_nnls["depth"], df_nnls["effort"], y_interaction_pred, c=y_interaction_pred, cmap="viridis", alpha=0.7)

# Labels and title
ax.set_xlabel("Depth")
ax.set_ylabel("Effort")
ax.set_zlabel("Predicted ARA")
ax.set_title("3D Visualization: Depth, Effort, and Predicted ARA (with Interaction)")

plt.show()























