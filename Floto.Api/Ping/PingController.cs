using Microsoft.AspNetCore.Mvc;
using Microsoft.FeatureManagement;

namespace Floto.Api.Ping
{
    [ApiController]
    [Route("v1/ping")]
    public class PingController : ControllerBase
    {
        private readonly IFeatureManager featureManager;
        private readonly ILogger<PingController> logger;
        private readonly string appVersion;
        private readonly string appStack;

        public PingController(IConfiguration config,
            IFeatureManager featureManager,
            ILogger<PingController> logger)
        {
            this.featureManager = featureManager;
            this.logger = logger;

            appVersion = config["Version"]!;

            appStack = config["Stack"]!;
        }

        [HttpGet]
        public async Task<ActionResult> Ping()
        {
            logger.LogDebug("{appVersion} | starting Ping", appVersion);

            string longVersion = $"{appStack}:{appVersion}";
            if (await featureManager.IsEnabledAsync("Beta"))
            {
                longVersion = string.Concat(longVersion, "-beta");
            }

            return new OkObjectResult(longVersion);
        }
    }
}
