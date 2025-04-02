# Boids in Zig using Raylib

![Boids Simulation Output](https://github.com/lazycodebaker/biods/blob/main/output.png)

## Overview
This is a Boids simulation implemented in Zig using Raylib. The Boids algorithm models flocking behavior of birds, where each agent (boid) follows three primary rules:
- **Separation**: Avoid crowding nearby boids.
- **Alignment**: Align velocity with neighboring boids.
- **Cohesion**: Move towards the average position of nearby boids.

## Features
- **Realistic flocking behavior** using vector mathematics.
- **Smooth movement and interactions** between boids.
- **Configurable parameters** for behavior tuning.
- **Efficient rendering** using Raylib.

## Installation & Running the Simulation

### Prerequisites
Ensure you have the following installed:
- [Zig](https://ziglang.org/download/)
- [Raylib](https://www.raylib.com/) (Zig bindings assumed)

### Steps
1. Clone this repository:
   ```sh
   git clone [https://github.com/yourusername/boids-zig.git](https://github.com/lazycodebaker/biods.git)
   cd boids-zig
   ```
2. Build the project:
   ```sh
   zig build
   ```
3. Run the simulation:
   ```sh
   zig-out/bin/boids
   ```

## Controls
- **Close Window**: Press `ESC` or click the close button.

## Configuration
Modify these parameters in `main.zig` to tweak boid behavior:
```zig
const avoidance_factor = 0.05;  // Influence of avoiding close boids
const matching_factor = 0.05;   // Influence of velocity alignment
const centering_factor = 0.0005; // Influence of moving towards nearby boids
const min_speed = 1.5;
const max_speed = 3;
const turn_padding = 100; // Screen edge avoidance buffer
const turn_factor = 0.2;  // Steering force at screen edges
```

## License
This project is released under the MIT License.

## Acknowledgments
- Inspired by Craig Reynolds' Boids algorithm.
- Built with [Zig](https://ziglang.org/) and [Raylib](https://www.raylib.com/).
