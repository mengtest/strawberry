#pragma once
#include <EntitasPP/IComponent.h>
#include <libfixmath/libfixmath/fixmath.h>

namespace Chestnut {
namespace Ball {

class PositionComponent :
	public Chestnut::EntitasPP::IComponent {
public:
	void Reset(fix16_t px, fix16_t py, fix16_t pz) {
		x = px;
		y = py;
		z = pz;
	}

	fix16_t x;
	fix16_t y;
	fix16_t z;
};
}
}