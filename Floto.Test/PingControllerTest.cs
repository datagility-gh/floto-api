using Floto.Api.Ping;

using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.FeatureManagement;

namespace Floto.Test;

public class PingControllerTest
{
    [Fact(DisplayName = "Returns 200 on success")]
    public async Task Ping_Succeeds()
    {
        Mock<IConfiguration> mockConfig = new Mock<IConfiguration>();
        Mock<IFeatureManager> mockFeatMan = new Mock<IFeatureManager>();
        Mock<ILogger<PingController>> mockLogger = new Mock<ILogger<PingController>>();

        PingController sut
            = new PingController(mockConfig.Object, mockFeatMan.Object, mockLogger.Object);

        ActionResult result = await sut.Ping();

        result.Should().BeOfType<OkObjectResult>();
    }

    [Fact(DisplayName = "Beta features enabled returns beta version")]
    public async Task Ping_Beta_Returns_Correctly()
    {
        Mock<IConfiguration> mockConfig = new Mock<IConfiguration>();
        Mock<IFeatureManager> mockFeatMan = new Mock<IFeatureManager>();
        Mock<ILogger<PingController>> mockLogger = new Mock<ILogger<PingController>>();

        mockFeatMan.Setup(fm =>
            fm.IsEnabledAsync(It.IsAny<string>())).ReturnsAsync(true);

        PingController sut
            = new PingController(mockConfig.Object, mockFeatMan.Object, mockLogger.Object);

        ActionResult result = await sut.Ping();
        Assert.IsType<OkObjectResult>(result);
        result.Should().BeOfType<OkObjectResult>();

        OkObjectResult objectResult = (OkObjectResult)result;
        objectResult.Value.Should().NotBeNull();
        objectResult.Value!.ToString().Should().EndWith("beta");
    }
}