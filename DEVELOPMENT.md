# Random notes

- PeriodicalScheduler calls Dash.Weather.Server
- Dash.Weather.Server uses Phoenix.PubSub (or Scenic sensor) to update Dash.Scene.Home

Sparkline modules

Dash.Sparkline.ScenicComponent
- Receives a %Contex.Sparkline{} and renders it to Scenic primitives

Dash.Sparkline
- Receives a %Contex.Sparkline{} and returns a %Dash.Sparkline{}

Dash.SvgPathParser
- Receives an SVG path (the `d` parameter) and parses it into draw commands
